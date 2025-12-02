import { runWithFailover } from "./lib/failover-core.ts";
import { getIntakeConfig } from "./config.ts";

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";

interface CacheEntry<T> {
  data: T;
  expires: number;
}

class CacheStore {
  private kv = await Deno.openKv();

  async get<T>(key: string): Promise<T | null> {
    try {
      const result = await this.kv.get([key]);
      if (!result.value) return null;

      const entry = result.value as CacheEntry<T>;
      if (Date.now() > entry.expires) {
        await this.kv.delete([key]);
        return null;
      }

      return entry.data;
    } catch {
      return null;
    }
  }

  async set<T>(key: string, data: T, ttlMs: number): Promise<void> {
    try {
      const entry: CacheEntry<T> = {
        data,
        expires: Date.now() + ttlMs,
      };
      await this.kv.set([key], entry, { expireIn: ttlMs });
    } catch {
      // Silently fail for cache issues
    }
  }
}

const cache = new CacheStore();
const CACHE_TTL_GROQ = 6 * 60 * 60 * 1000; // 6 hours

export type GroqCompletionSource = "groq" | "secondary";

export interface GroqCompletionResult {
  data: unknown;
  cacheHit: boolean;
  source: GroqCompletionSource;
}

const intakeConfig = getIntakeConfig();
export const secondaryConfigured = Boolean(intakeConfig.secondaryLLM);

export async function runGroqCompletion(
  prompt: string,
): Promise<GroqCompletionResult> {
  const cacheKey = await hashPrompt(prompt);
  const cached = await cache.get<unknown>(cacheKey);
  if (cached) {
    return { data: cached, cacheHit: true, source: "groq" };
  }

  const fetchResult = await runWithFailover(
    () => fetchGroq(prompt),
    secondaryConfigured ? () => callSecondaryLLM(prompt) : undefined,
  );

  if (fetchResult.source === "groq" && fetchResult.data) {
    await cache.set(cacheKey, fetchResult.data, CACHE_TTL_GROQ);
  }

  return {
    data: fetchResult.data,
    cacheHit: false,
    source: fetchResult.source,
  };
}

async function fetchGroq(prompt: string): Promise<unknown> {
  const apiKey = intakeConfig.groqApiKey;
  if (!apiKey) {
    throw new Error("GROQ_API_KEY not configured");
  }

  const body = {
    model: "llama-3.1-70b-versatile",
    messages: [{ role: "user", content: prompt }],
    temperature: 0.1,
    response_format: { type: "json_object" },
  };

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

  try {
    const response = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    if (!response.ok) {
      const message = await response.text();
      throw new Error(`Groq API failed: ${message}`);
    }

    const payload = await response.json();
    return payload.choices?.[0]?.message?.content;
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error("Groq API request timed out after 30 seconds");
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

async function hashPrompt(prompt: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(prompt);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function callSecondaryLLM(prompt: string): Promise<unknown> {
  const secondary = intakeConfig.secondaryLLM;
  if (!secondary) {
    throw new Error("secondary_not_configured");
  }

  // TODO: Wire up actual secondary provider.
  throw new Error("secondary_llm_not_implemented");
}
