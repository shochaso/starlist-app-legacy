import { describe, it, expect } from "vitest";
import { runWithFailover } from "../supabase/functions/intake/_shared/lib/failover-core.ts";

describe("failover core runWithFailover", () => {
  it("returns the primary result when no error occurs", async () => {
    const result = await runWithFailover(
      async () => "primary",
      async () => "secondary",
    );
    expect(result.source).toBe("primary");
    expect(result.value).toBe("primary");
  });

  it("falls back to secondary when primary fails", async () => {
    const result = await runWithFailover<string>(
      async () => {
        throw new Error("boom");
      },
      async () => "secondary",
    );
    expect(result.source).toBe("secondary");
    expect(result.value).toBe("secondary");
  });

  it("throws when both primary and secondary fail", async () => {
    await expect(
      runWithFailover(
        async () => {
          throw new Error("primary");
        },
        async () => {
          throw new Error("secondary");
        },
      ),
    ).rejects.toThrow("secondary");
  });
});



