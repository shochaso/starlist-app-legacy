import { ParsedItem } from "./parser.ts";
import { INTAKE_API_VERSION } from "../../../../shared/intake-version.ts";

export interface IntakeItem {
  title: string;
  channel: string;
  time: string | null;
  videoId: string;
  duration: string;
  thumbnails: Record<string, unknown>;
}

export interface IntakeHealth {
  status: "ok";
  version: string;
  timestamp: string;
  checks: {
    rate_limit: "ok" | "disabled";
    metrics: "ok" | "disabled" | "misconfigured";
    llm: "primary_only" | "secondary_configured";
  };
}

export interface IntakeResponse {
  version: string;
  items: IntakeItem[];
  health?: IntakeHealth;
}

export interface EnrichResult {
  response: IntakeResponse;
  youtubeCacheHit: boolean;
}

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
const CACHE_TTL_YOUTUBE = 24 * 60 * 60 * 1000; // 24 hours

function convertIsoDuration(raw: string): string {
  const matches = Array.from(raw.matchAll(/(\d+)([HMS])/g));
  let hours = 0;
  let minutes = 0;
  let seconds = 0;
  matches.forEach((match) => {
    const value = Number(match[1]);
    if (match[2] === "H") hours = value;
    if (match[2] === "M") minutes = value;
    if (match[2] === "S") seconds = value;
  });
  if (hours) {
    return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

async function enrichYoutubeItemsInternal(
  items: ParsedItem[],
): Promise<EnrichResult> {
  const key = Deno.env.get("YOUTUBE_API_KEY");
  if (!key) {
    throw new Error("YOUTUBE_API_KEY not configured");
  }

  let youtubeCacheHit = false;

  const enriched = await Promise.all(
    items.map(async (item) => {
      if (!item.videoId) {
        return fallbackItem(item, true);
      }

      const cacheKey = `yt:video:${item.videoId}`;
      const cached = await cache.get<IntakeItem>(cacheKey);
      if (cached) {
        youtubeCacheHit = true;
        return {
          ...cached,
          title: item.title,
          channel: item.channel,
          time: item.time,
        };
      }

      const url = new URL("https://www.googleapis.com/youtube/v3/videos");
      url.searchParams.set("id", item.videoId);
      url.searchParams.set("part", "snippet,contentDetails");
      url.searchParams.set("key", key);

      try {
        const response = await fetch(url.toString());
        if (!response.ok) {
          console.error(`YouTube API failed for ${item.videoId}:`, response.status);
          return fallbackItem(item, true);
        }

        const payload = await response.json();
        const video = Array.isArray(payload?.items) ? payload.items[0] : null;
        if (!video) {
          return fallbackItem(item, true);
        }

        const enrichedItem = {
          title: item.title,
          channel: item.channel,
          time: item.time,
          videoId: String(video.id ?? ""),
          duration: convertIsoDuration(video.contentDetails?.duration ?? ""),
          thumbnails: video.snippet?.thumbnails?.medium ?? {},
        };

        await cache.set(cacheKey, enrichedItem, CACHE_TTL_YOUTUBE);
        return enrichedItem;
      } catch (error) {
        console.error(`YouTube fetch error for ${item.videoId}:`, error);
        return fallbackItem(item, true);
      }
    })
  );

  return {
    response: {
      version: INTAKE_API_VERSION,
      items: enriched,
    },
    youtubeCacheHit,
  };
}

export async function enrichYoutubeItems(
  items: ParsedItem[],
): Promise<IntakeResponse> {
  return (await enrichYoutubeItemsInternal(items)).response;
}

export async function enrichYoutubeItemsWithCache(
  items: ParsedItem[],
): Promise<EnrichResult> {
  return enrichYoutubeItemsInternal(items);
}

function fallbackItem(item: ParsedItem, dropId = false): IntakeItem {
  return {
    title: item.title,
    channel: item.channel,
    time: item.time,
    videoId: dropId ? "" : item.videoId,
    duration: "",
    thumbnails: {},
  };
}
