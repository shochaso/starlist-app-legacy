export interface RateLimitStore {
  read(key: string): Promise<number | null>;
  write(key: string, value: number, ttlMs: number): Promise<void>;
}

export interface RateLimitThresholds {
  perMinute: number;
  perDay: number;
}

export type RateLimitWindow = "minute" | "day";

export class RateLimitError extends Error {
  retryAfterSeconds: number;
  limitPerMinute: number;
  limitPerDay: number;
  window: RateLimitWindow;

  constructor(
    retryAfterSeconds: number,
    window: RateLimitWindow,
    thresholds: RateLimitThresholds,
  ) {
    super("rate limit exceeded");
    this.retryAfterSeconds = retryAfterSeconds;
    this.limitPerMinute = thresholds.perMinute;
    this.limitPerDay = thresholds.perDay;
    this.window = window;
  }
}

export class RateLimiter {
  private static MINUTE_MS = 60_000;
  private static DAY_MS = 24 * 60 * 60 * 1000;

  constructor(
    private store: RateLimitStore,
    private thresholds: RateLimitThresholds,
  ) {}

  async check(identifier: string, now = Date.now()): Promise<void> {
    if (this.thresholds.perMinute > 0) {
      const minuteResult = await this.increment(identifier, "minute", now);
      if (minuteResult.exceeded) {
        throw new RateLimitError(
          minuteResult.retryAfterSeconds,
          "minute",
          this.thresholds,
        );
      }
    }

    if (this.thresholds.perDay > 0) {
      const dayResult = await this.increment(identifier, "day", now);
      if (dayResult.exceeded) {
        throw new RateLimitError(
          dayResult.retryAfterSeconds,
          "day",
          this.thresholds,
        );
      }
    }
  }

  private async increment(
    identifier: string,
    window: RateLimitWindow,
    now: number,
  ): Promise<{ exceeded: boolean; retryAfterSeconds: number }> {
    const windowMs =
      window === "minute" ? RateLimiter.MINUTE_MS : RateLimiter.DAY_MS;
    const windowStart = Math.floor(now / windowMs) * windowMs;
    const key = `${identifier}:${window}:${windowStart}`;
    const current = (await this.store.read(key)) ?? 0;
    const next = current + 1;
    await this.store.write(key, next, windowMs + 1_000);
    if (next > (window === "minute"
      ? this.thresholds.perMinute
      : this.thresholds.perDay)) {
      const retryMs = windowStart + windowMs - now;
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil(retryMs / 1000),
      );
      return { exceeded: true, retryAfterSeconds };
    }
    return { exceeded: false, retryAfterSeconds: 0 };
  }
}

export class InMemoryRateLimitStore implements RateLimitStore {
  private data = new Map<string, { expiresAt: number; value: number }>();

  async read(key: string): Promise<number | null> {
    const record = this.data.get(key);
    if (!record) return null;
    if (Date.now() > record.expiresAt) {
      this.data.delete(key);
      return null;
    }
    return record.value;
  }

  async write(key: string, value: number, ttlMs: number): Promise<void> {
    this.data.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
    });
  }
}



