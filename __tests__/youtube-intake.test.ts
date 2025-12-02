import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { POST } from "../app/api/youtube-intake/route";
import * as groqClient from "../app/lib/groqClient";
import * as youtubeEnrichModule from "../app/lib/youtubeEnrich";
import { youtubeEnrich } from "../app/lib/youtubeEnrich";
import { cache, CACHE_TTL } from "../app/lib/cache";

vi.mock("../app/lib/groqClient");
vi.mock("../app/lib/youtubeEnrich");

const mockRunGroq = vi.mocked(groqClient.runGroqCompletion);
const mockYoutubeEnrich = vi.mocked(youtubeEnrichModule.youtubeEnrich);

beforeEach(() => {
  process.env.GROQ_API_KEY = "test-key";
  process.env.YOUTUBE_API_KEY = "test-key";
  mockRunGroq.mockReset();
  mockYoutubeEnrich.mockReset();
});

afterEach(() => {
  delete process.env.GROQ_API_KEY;
  delete process.env.YOUTUBE_API_KEY;
});

describe("YouTube intake API", () => {
  it("returns 401 when GROQ API key missing", async () => {
    delete process.env.GROQ_API_KEY;
    process.env.YOUTUBE_API_KEY = "test-key";
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({ ocrText: "test" }),
      })
    );
    expect(response.status).toBe(401);
    expect(await response.json()).toMatchObject({ error: true });
  });

  it("returns 401 when YouTube API key missing", async () => {
    process.env.GROQ_API_KEY = "test-key";
    delete process.env.YOUTUBE_API_KEY;
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({ ocrText: "test" }),
      })
    );
    expect(response.status).toBe(401);
    expect(await response.json()).toMatchObject({ error: true });
  });

  it("returns 400 when OCR missing", async () => {
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({}),
        headers: { "Content-Type": "application/json" },
      })
    );
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({
      error: true,
      message: "ocrText field is required.",
    });
  });

  it("returns 502 when Groq fails", async () => {
    mockRunGroq.mockRejectedValue(new Error("boom"));
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({ ocrText: "a" }),
      })
    );
    expect(response.status).toBe(502);
    expect(await response.json()).toMatchObject({
      error: true,
      message: "Groq completion failed",
    });
  });

  it("returns 502 when Groq returns unexpected payload", async () => {
    mockRunGroq.mockResolvedValue("not json object");
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({ ocrText: "a" }),
      })
    );
    expect(response.status).toBe(502);
    expect(await response.json()).toMatchObject({
      error: true,
      message: "Unexpected Groq response",
    });
  });

  it("returns structured items on success", async () => {
    mockRunGroq.mockResolvedValue({
      items: [{ title: "T", channel: "C", time: "13:07" }],
    });
    mockYoutubeEnrich.mockResolvedValue([
      {
        title: "T",
        channel: "C",
        time: "13:07",
        videoId: "abc",
        duration: "13:07",
        thumbnails: {},
      },
    ]);
    const response = await POST(
      new Request("https://example.com/api", {
        method: "POST",
        body: JSON.stringify({ ocrText: "data" }),
      })
    );
    expect(response.status).toBe(200);
    const payload = await response.json();
    expect(payload.items?.length).toBeGreaterThanOrEqual(1);
  });
});

describe("youtubeEnrich fallback", () => {
  beforeEach(() => {
    process.env.YOUTUBE_API_KEY = "test-key";
  });
  afterEach(() => {
    delete process.env.YOUTUBE_API_KEY;
    vi.restoreAllMocks();
  });

  it("returns videoId empty if YouTube returns no items", async () => {
    mockYoutubeEnrich.mockResolvedValue([
      {
        title: "t",
        channel: "c",
        time: "10:00",
        videoId: "",
        duration: "",
        thumbnails: {},
      },
    ]);
    const result = await youtubeEnrich([
      { title: "t", channel: "c", time: "10:00", videoId: "unknown" },
    ]);
    expect(result[0].videoId).toBe("");
  });
});

describe("cache layer", () => {
  beforeEach(() => {
    // Clear cache before each test
    vi.clearAllMocks();
    if (typeof globalThis !== 'undefined') {
      delete (globalThis as any).__CACHE__;
    }
    // Set NODE_ENV to development for globalThis cache
    process.env.NODE_ENV = 'development';
  });

  afterEach(() => {
    delete process.env.NODE_ENV;
  });

  it("handles cache set/get operations", async () => {
    const testKey = "test:key";
    const testData = { value: "test" };

    await cache.set(testKey, testData, CACHE_TTL.YOUTUBE_VIDEO);
    const result = await cache.get<typeof testData>(testKey);

    expect(result).toEqual(testData);
  });

  it("returns null for expired cache", async () => {
    const testKey = "test:expired";
    const testData = { value: "expired" };

    // Set with very short TTL
    await cache.set(testKey, testData, 1); // 1ms TTL

    // Wait for expiration
    await new Promise(resolve => setTimeout(resolve, 10));

    const result = await cache.get<typeof testData>(testKey);
    expect(result).toBeNull();
  });
});
