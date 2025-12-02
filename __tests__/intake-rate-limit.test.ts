import { describe, it, expect } from "vitest";
import {
  RateLimiter,
  RateLimitError,
  InMemoryRateLimitStore,
} from "../supabase/functions/intake/_shared/lib/rate-core.ts";

describe("RateLimiter core", () => {
  it("allows requests until the minute limit is hit", async () => {
    const limiter = new RateLimiter(
      new InMemoryRateLimitStore(),
      { perMinute: 2, perDay: 10 },
    );

    await limiter.check("user-a");
    await limiter.check("user-a");

    await expect(limiter.check("user-a")).rejects.toBeInstanceOf(RateLimitError);
    try {
      await limiter.check("user-a");
    } catch (error) {
      expect((error as RateLimitError).window).toBe("minute");
      expect((error as RateLimitError).retryAfterSeconds).toBeGreaterThan(0);
    }
  });

  it("enforces the day limit independently of the minute window", async () => {
    const limiter = new RateLimiter(
      new InMemoryRateLimitStore(),
      { perMinute: 1000, perDay: 3 },
    );

    await limiter.check("user-b");
    await limiter.check("user-b");
    await limiter.check("user-b");

    await expect(limiter.check("user-b")).rejects.toBeInstanceOf(RateLimitError);
  });
});


