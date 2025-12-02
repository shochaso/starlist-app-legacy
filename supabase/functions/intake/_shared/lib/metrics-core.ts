export type CacheHitLabel = "none" | "groq" | "youtube" | "both";

export interface IntakeMetricPayload {
  success: boolean;
  latencyMs: number;
  cacheHit: CacheHitLabel;
  source: string;
  errorCode?: string;
  userId?: string;
  starId?: string;
}

export interface IntakeMetricRecord {
  user_id: string | null;
  star_id: string | null;
  success: boolean;
  latency_ms: number;
  cache_hit: CacheHitLabel;
  error_code: string | null;
  source: string;
}

export function describeCacheHit(
  groqCacheHit: boolean,
  youtubeCacheHit: boolean,
): CacheHitLabel {
  if (groqCacheHit && youtubeCacheHit) return "both";
  if (groqCacheHit) return "groq";
  if (youtubeCacheHit) return "youtube";
  return "none";
}

export async function hashIdentifier(value: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function buildMetricRecord(
  payload: IntakeMetricPayload,
): Promise<IntakeMetricRecord> {
  const userIdHash = payload.userId ? await hashIdentifier(payload.userId) : null;
  const starIdHash = payload.starId ? await hashIdentifier(payload.starId) : null;
  return {
    user_id: userIdHash,
    star_id: starIdHash,
    success: payload.success,
    latency_ms: Math.max(0, Math.floor(payload.latencyMs)),
    cache_hit: payload.cacheHit,
    error_code: payload.errorCode ?? null,
    source: payload.source,
  };
}


