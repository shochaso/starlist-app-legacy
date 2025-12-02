import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { handleIntakeRequest } from "../supabase/functions/intake/_shared/handler.ts";
import { RateLimitError } from "../supabase/functions/intake/_shared/rate.ts";
import { INTAKE_API_VERSION } from "../shared/intake-version.ts";

// Mock dependencies
vi.mock("../supabase/functions/intake/_shared/groq.ts", () => ({
  runGroqCompletion: vi.fn(),
  secondaryConfigured: false,
  callSecondaryLLM: vi.fn(),
}));

vi.mock("../supabase/functions/intake/_shared/metrics.ts", () => ({
  initIntakeMetrics: vi.fn(),
  logIntakeMetric: vi.fn(),
}));

vi.mock("../supabase/functions/intake/_shared/youtube.ts", () => ({
  enrichYoutubeItemsWithCache: vi.fn(),
}));

vi.mock("../supabase/functions/intake/_shared/rate.ts", () => ({
  configureRateLimiter: vi.fn(),
  enforceRateLimitFor: vi.fn(),
  RateLimitError: class RateLimitError extends Error {
    retryAfterSeconds = 30;
    limitPerMinute = 5;
    limitPerDay = 200;
    window = "minute";
    constructor() {
      super("Rate limit exceeded");
      this.name = "RateLimitError";
    }
  },
}));

vi.mock("../supabase/functions/intake/_shared/config.ts", () => ({
  getIntakeConfig: () => ({
    groqApiKey: "test-key",
    youtubeApiKey: "test-key",
    rateLimitPerMinute: 5,
    rateLimitPerDay: 200,
    rateLimitDisabled: false,
    metricsEnabled: false,
    supabaseUrl: null,
    supabaseServiceRoleKey: null,
    secondaryLLM: null,
  }),
}));

import * as groqModule from "../supabase/functions/intake/_shared/groq.ts";
import * as metricsModule from "../supabase/functions/intake/_shared/metrics.ts";
import * as youtubeModule from "../supabase/functions/intake/_shared/youtube.ts";
import * as rateModule from "../supabase/functions/intake/_shared/rate.ts";

const mockRunGroq = vi.mocked(groqModule.runGroqCompletion);
const mockLogMetric = vi.mocked(metricsModule.logIntakeMetric);
const mockEnrich = vi.mocked(youtubeModule.enrichYoutubeItemsWithCache);
const mockEnforceRateLimit = vi.mocked(rateModule.enforceRateLimitFor);

describe("Intake Handler Integration", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockEnforceRateLimit.mockResolvedValue(undefined);
    mockLogMetric.mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("returns versioned response on success", async () => {
    mockRunGroq.mockResolvedValue({
      data: { items: [{ title: "Test", channel: "Channel", time: "12:00", videoId: "abc123" }] },
      cacheHit: false,
      source: "groq",
    });
    mockEnrich.mockResolvedValue({
      response: {
        version: INTAKE_API_VERSION,
        items: [
          {
            title: "Test",
            channel: "Channel",
            time: "12:00",
            videoId: "abc123",
            duration: "10:00",
            thumbnails: {},
          },
        ],
      },
      youtubeCacheHit: false,
    });

    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "test ocr text" }),
    });

    const response = await handleIntakeRequest(req);

    expect(response.version).toBe(INTAKE_API_VERSION);
    expect(response.items).toHaveLength(1);
    expect(response.items[0].title).toBe("Test");
  });

  it("enforces rate limiting and throws RateLimitError", async () => {
    mockEnforceRateLimit.mockRejectedValue(new rateModule.RateLimitError());

    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "test" }),
    });

    await expect(handleIntakeRequest(req)).rejects.toBeInstanceOf(
      rateModule.RateLimitError,
    );
  });

  it("logs metrics when enabled", async () => {
    mockRunGroq.mockResolvedValue({
      data: { items: [] },
      cacheHit: false,
      source: "groq",
    });
    mockEnrich.mockResolvedValue({
      response: { version: INTAKE_API_VERSION, items: [] },
      youtubeCacheHit: false,
    });

    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "test" }),
    });

    await handleIntakeRequest(req);

    // Metrics should be called even if disabled (it checks internally)
    // The actual logging is best-effort
    expect(mockLogMetric).toHaveBeenCalled();
  });

  it("handles health check requests", async () => {
    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "__HEALTHCHECK__" }),
    });

    const response = await handleIntakeRequest(req);

    expect(response.version).toBe(INTAKE_API_VERSION);
    expect(response.health).toBeDefined();
    expect(response.health?.status).toBe("ok");
    expect(response.items).toHaveLength(0);
  });

  it("returns fallback response when Groq fails", async () => {
    mockRunGroq.mockRejectedValue(new Error("Groq timeout"));

    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "test ocr text here" }),
    });

    const response = await handleIntakeRequest(req);

    expect(response.version).toBe(INTAKE_API_VERSION);
    expect(response.items).toHaveLength(1);
    expect(response.items[0].videoId).toBe("");
    // Fallback should include a snippet of OCR text
    expect(response.items[0].title).toContain("test ocr");
  });

  it("includes version in all responses", async () => {
    mockRunGroq.mockResolvedValue({
      data: { items: [] },
      cacheHit: false,
      source: "groq",
    });
    mockEnrich.mockResolvedValue({
      response: { version: INTAKE_API_VERSION, items: [] },
      youtubeCacheHit: false,
    });

    const req = new Request("https://example.com", {
      method: "POST",
      body: JSON.stringify({ ocrText: "test" }),
    });

    const response = await handleIntakeRequest(req);
    expect(response.version).toBe(INTAKE_API_VERSION);
  });
});


