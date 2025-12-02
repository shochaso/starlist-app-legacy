import { ParsedItem } from "./parser.ts";

export interface IntakeItem {
  title: string;
  channel: string;
  time: string | null;
  videoId: string;
  duration: string;
  thumbnails: Record<string, unknown>;
}

export interface IntakeResponse {
  items: IntakeItem[];
}

const convertIsoDuration = (raw: string): string => {
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
    return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(
      2,
      "0"
    )}:${String(seconds).padStart(2, "0")}`;
  }
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
};

export async function enrichYoutubeItems(
  items: ParsedItem[]
): Promise<IntakeResponse> {
  const key = Deno.env.get("YOUTUBE_API_KEY");
  const enriched = await Promise.all(
    items.map(async (item) => {
      if (!key || !item.videoId) {
        return fallbackItem(item, true);
      }
      const url = new URL("https://www.googleapis.com/youtube/v3/videos");
      url.searchParams.set("id", item.videoId);
      url.searchParams.set("part", "snippet,contentDetails");
      url.searchParams.set("key", key);

      try {
        const response = await fetch(url.toString());
        if (!response.ok) {
          console.error("YouTube videos.list failed", response.status);
          return fallbackItem(item, true);
        }
        const payload = await response.json();
        const video = Array.isArray(payload?.items) ? payload.items[0] : null;
        if (!video) {
          return fallbackItem(item, true);
        }

        return {
          title: item.title,
          channel: item.channel,
          time: item.time,
          videoId: String(video.id ?? ""),
          duration: convertIsoDuration(video.contentDetails?.duration ?? ""),
          thumbnails: video.snippet?.thumbnails?.medium ?? {},
        };
      } catch (error) {
        console.error("YouTube fetch error", error);
        return fallbackItem(item, true);
      }
    })
  );

  return { items: enriched };
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
