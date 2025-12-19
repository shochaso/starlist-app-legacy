import {
  RateLimitError,
  RateLimitThresholds,
  RateLimiter,
  RateLimitStore,
} from "./lib/rate-core.ts";

class DenoKvRateLimitStore implements RateLimitStore {
  private kvPromise = Deno.openKv();

  async read(key: string): Promise<number | null> {
    try {
      const kv = await this.kvPromise;
      const result = await kv.get([key]);
      if (!result.value) return null;
      const entry = result.value as { value: number; expires: number };
      if (Date.now() > entry.expires) {
        await kv.delete([key]);
        return null;
      }
      return entry.value;
    } catch {
      return null;
    }
  }

  async write(key: string, value: number, ttlMs: number): Promise<void> {
    try {
      const kv = await this.kvPromise;
      const entry = {
        value,
        expires: Date.now() + ttlMs,
      };
      await kv.set([key], entry, { expireIn: ttlMs });
    } catch {
      // best effort
    }
  }
}

let rateLimiter: RateLimiter | null = null;
let rateLimitDisabled = false;

export function configureRateLimiter(
  thresholds: RateLimitThresholds,
  disabled: boolean,
): void {
  rateLimitDisabled = disabled;
  rateLimiter = disabled ? null : new RateLimiter(new DenoKvRateLimitStore(), thresholds);
}

export async function enforceRateLimitFor(
  identifier: string,
): Promise<void> {
  if (rateLimitDisabled) return;
  if (!rateLimiter || !identifier) return;
  await rateLimiter.check(identifier);
}

export { RateLimitError };



