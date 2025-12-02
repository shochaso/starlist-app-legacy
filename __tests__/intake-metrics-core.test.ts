import { describe, it, expect } from "vitest";
import {
  describeCacheHit,
  hashIdentifier,
} from "../supabase/functions/intake/_shared/lib/metrics-core.ts";

describe("metrics helpers", () => {
  it("reports cache hit labels correctly", () => {
    expect(describeCacheHit(false, false)).toBe("none");
    expect(describeCacheHit(true, false)).toBe("groq");
    expect(describeCacheHit(false, true)).toBe("youtube");
    expect(describeCacheHit(true, true)).toBe("both");
  });

  it("hashes identifiers consistently", async () => {
    const first = await hashIdentifier("abc");
    const second = await hashIdentifier("abc");
    expect(first).toBe(second);
    expect(first).toHaveLength(64);
  });
});


