import {
  IntakeHealth,
  IntakeResponse,
  enrichYoutubeItemsWithCache,
} from "./youtube.ts";
import {
  callSecondaryLLM,
  runGroqCompletion,
  secondaryConfigured,
} from "./groq.ts";
import {
  parseGroqItems,
  safeParseGroqResponse,
} from "./parser.ts";
import {
  configureRateLimiter,
  enforceRateLimitFor,
  RateLimitError,
} from "./rate.ts";
import { initIntakeMetrics, logIntakeMetric } from "./metrics.ts";
import {
  describeCacheHit,
  hashIdentifier,
  type IntakeMetricPayload,
} from "./lib/metrics-core.ts";
import { getIntakeConfig } from "./config.ts";
import { INTAKE_API_VERSION } from "../../../../shared/intake-version.ts";

const intakeConfig = getIntakeConfig();
configureRateLimiter(
  {
    perMinute: intakeConfig.rateLimitPerMinute,
    perDay: intakeConfig.rateLimitPerDay,
  },
  intakeConfig.rateLimitDisabled,
);
initIntakeMetrics(intakeConfig);

const promptTemplate = `You are an assistant that extracts YouTube watch history from OCR.
OCR:
{OCR_PLACEHOLDER}

Return strict JSON:
{
  "items": [
    {
      "title": "...",
      "channel": "...",
      "time": "12:41" or null,
      "videoId": "" or null
    }
  ]
}`;

const METRIC_SOURCE = "youtube_ocr";
const HEALTH_CHECK_TOKEN = "__HEALTHCHECK__";

interface IntakeRequestPayload {
  ocrText?: string;
  userId?: string;
  starId?: string;
  healthCheck?: boolean;
}

interface IdentityResult {
  identifier: string;
  userHash: string | null;
  starHash: string | null;
  method: "star" | "user" | "anonymous";
}

export async function handleIntakeRequest(req: Request): Promise<IntakeResponse> {
  const start = Date.now();
  const metricPayload: IntakeMetricPayload = {
    success: false,
    latencyMs: 0,
    cacheHit: "none",
    source: METRIC_SOURCE,
  };
  const requestId = getRequestId(req);
  let identity: IdentityResult = {
    identifier: "",
    userHash: null,
    starHash: null,
    method: "anonymous",
  };
  let shouldLogMetrics = true;

  try {
    const payload = await parsePayload(req);
    identity = await resolveRateLimitIdentity(req, payload, requestId);
    metricPayload.userId = payload.userId ?? null;
    metricPayload.starId = payload.starId ?? null;

    logIntakeEvent(requestId, "request.received", identity);

    if (payload.healthCheck) {
      shouldLogMetrics = false;
      return buildHealthResponse();
    }

    await enforceRateLimitFor(identity.identifier);

    const prompt = promptTemplate.replace("{OCR_PLACEHOLDER}", payload.ocrText);
    const { response: intakeResponse } = await processPrompt(
      prompt,
      payload.ocrText,
      metricPayload,
      { requestId, identity },
    );

    logIntakeEvent(requestId, "request.success", {
      ...identity,
      cacheHit: metricPayload.cacheHit,
    });
    metricPayload.success = true;

    return intakeResponse;
  } catch (error) {
    if (error instanceof RateLimitError) {
      metricPayload.errorCode = "rate_limited";
      logIntakeEvent(requestId, "request.rate_limited", {
        ...identity,
        retryAfterSeconds: error.retryAfterSeconds,
        window: error.window,
      });
      throw error;
    }
    logIntakeEvent(requestId, "request.failure", {
      ...identity,
      error: metricPayload.errorCode ?? "unknown",
    });
    throw error;
  } finally {
    metricPayload.latencyMs = Date.now() - start;
    if (shouldLogMetrics) {
      await logIntakeMetric(metricPayload);
    }
  }
}

async function processPrompt(
  prompt: string,
  ocrText: string,
  metricPayload: IntakeMetricPayload,
  context: { requestId: string; identity: IdentityResult },
): Promise<{ response: IntakeResponse }> {
  let groqResult: unknown;
  let cachedGroqResult = false;

  try {
    const result = await runGroqCompletion(prompt);
    groqResult = result.data;
    cachedGroqResult = result.cacheHit;
  } catch (error) {
    metricPayload.errorCode = deriveGroqErrorCode(error);
    logIntakeEvent(context.requestId, "llm.failure", {
      ...context.identity,
      step: "groq",
      code: metricPayload.errorCode,
    });
    const fallback = buildFallbackResponse(ocrText);
    return { response: fallback };
  }

  let groqItems = safeParseGroqResponse(groqResult);

  if (!groqItems) {
    metricPayload.errorCode = "groq_invalid_response";
    logIntakeEvent(context.requestId, "llm.invalid_response", {
      ...context.identity,
      code: metricPayload.errorCode,
    });
    if (secondaryConfigured) {
      try {
        groqResult = await callSecondaryLLM(prompt);
        groqItems = safeParseGroqResponse(groqResult);
        if (!groqItems) {
          metricPayload.errorCode = "secondary_invalid_response";
        } else {
          logIntakeEvent(context.requestId, "llm.secondary_success", {
            ...context.identity,
          });
        }
      } catch (error) {
        metricPayload.errorCode = deriveGroqErrorCode(error);
        logIntakeEvent(context.requestId, "llm.secondary_failure", {
          ...context.identity,
          code: metricPayload.errorCode,
        });
      }
    }
  }

  if (!groqItems) {
    metricPayload.errorCode ??= "llm_fallback";
    const fallback = buildFallbackResponse(ocrText);
    return { response: fallback };
  }

  const parsedItems = parseGroqItems(groqItems);
  const { response: enrichedResponse, youtubeCacheHit } =
    await enrichYoutubeItemsWithCache(parsedItems);

  metricPayload.cacheHit = describeCacheHit(
    cachedGroqResult,
    youtubeCacheHit,
  );
  metricPayload.errorCode = undefined;

  return { response: enrichedResponse };
}

async function parsePayload(req: Request): Promise<IntakeRequestPayload> {
  const payload = await req.json().catch(() => {
    throw new Error("Request JSON parse failed");
  });
  if (!payload || typeof payload !== "object") {
    throw new Error("ocrText field is required");
  }
  const ocrCandidate = (payload as { ocrText?: unknown }).ocrText;
  if (typeof ocrCandidate !== "string" || !ocrCandidate.trim()) {
    throw new Error("ocrText field is required");
  }
  const normalized = ocrCandidate.trim();
  return {
    ...(payload as IntakeRequestPayload),
    ocrText: normalized,
    healthCheck: normalized === HEALTH_CHECK_TOKEN,
  };
}

async function resolveRateLimitIdentity(
  req: Request,
  payload: IntakeRequestPayload,
  requestId: string,
): Promise<IdentityResult> {
  const starId = payload.starId?.trim();
  if (starId) {
    const starHash = await hashIdentifier(`star:${starId}`);
    return {
      identifier: starHash,
      userHash: null,
      starHash,
      method: "star",
    };
  }

  const userId = payload.userId?.trim() ?? extractJwtSubject(req);
  if (userId) {
    const userHash = await hashIdentifier(`user:${userId}`);
    return {
      identifier: userHash,
      userHash,
      starHash: null,
      method: "user",
    };
  }

  const anonymousHash = await hashIdentifier(`anonymous:${requestId}`);
  return {
    identifier: anonymousHash,
    userHash: null,
    starHash: null,
    method: "anonymous",
  };
}

function extractJwtSubject(req: Request): string | null {
  const header = req.headers.get("authorization") ??
    req.headers.get("Authorization");
  if (!header) return null;
  const match = header.match(/Bearer\s+(.+)/i);
  if (!match) return null;
  const token = match[1];
  const payloadSegment = token.split(".")[1];
  if (!payloadSegment) return null;
  try {
    const decoded = base64UrlDecode(payloadSegment);
    const parsed = JSON.parse(decoded);
    return typeof parsed?.sub === "string"
      ? parsed.sub
      : typeof parsed?.user_id === "string"
        ? parsed.user_id
        : null;
  } catch {
    return null;
  }
}

function base64UrlDecode(value: string): string {
  let padded = value.replace(/-/g, "+").replace(/_/g, "/");
  const remainder = padded.length % 4;
  if (remainder === 2) padded += "==";
  else if (remainder === 3) padded += "=";
  else if (remainder === 1) padded += "===";

  if (typeof atob === "function") {
    return atob(padded);
  }

  const bufferCtor = (globalThis as typeof globalThis & {
    Buffer?: typeof Buffer;
  }).Buffer;
  if (bufferCtor) {
    return bufferCtor.from(padded, "base64").toString("utf-8");
  }

  return "";
}

function deriveGroqErrorCode(error: unknown): string {
  if (error instanceof Error) {
    const lower = error.message.toLowerCase();
    if (lower.includes("timed out")) return "groq_timeout";
    if (lower.includes("secondary")) return "secondary_llm_failed";
  }
  return "groq_failure";
}

function buildFallbackResponse(ocrText: string): IntakeResponse {
  const trimmed = ocrText?.trim() ?? "";
  const snippet = trimmed.slice(0, 200) || "Unable to parse watch history OCR.";
  return {
    version: INTAKE_API_VERSION,
    items: [
      {
        title: snippet,
        channel: "",
        time: null,
        videoId: "",
        duration: "",
        thumbnails: {},
      },
    ],
  };
}

function buildHealthResponse(): IntakeResponse {
  return {
    version: INTAKE_API_VERSION,
    items: [],
    health: buildHealthStatus(),
  };
}

function buildHealthStatus(): IntakeHealth {
  const rate_limit = intakeConfig.rateLimitDisabled ? "disabled" : "ok";
  const metrics =
    intakeConfig.metricsEnabled &&
        intakeConfig.supabaseUrl &&
        intakeConfig.supabaseServiceRoleKey
      ? "ok"
      : intakeConfig.metricsEnabled
      ? "misconfigured"
      : "disabled";
  const llm = secondaryConfigured ? "secondary_configured" : "primary_only";

  return {
    status: "ok",
    version: INTAKE_API_VERSION,
    timestamp: new Date().toISOString(),
    checks: {
      rate_limit,
      metrics,
      llm,
    },
  };
}

function getRequestId(req: Request): string {
  const header = req.headers.get("x-request-id") ??
    req.headers.get("x-correlation-id");
  if (header && header.trim()) return header.trim();
  if (typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function logIntakeEvent(
  requestId: string,
  event: string,
  detail: Record<string, unknown>,
): void {
  const payload = {
    scope: "intake",
    requestId,
    event,
    timestamp: new Date().toISOString(),
    ...detail,
  };
  console.info(JSON.stringify(payload));
}
