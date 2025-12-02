import { IntakeItem } from "../types/youtube-intake";
import { ParsedItem } from "./parseYoutubeOCR";

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY ?? "";

export async function youtubeEnrich(items: ParsedItem[]): Promise<IntakeItem[]> {
  const results = await Promise.all(
    items.map(async (item) => {
      const trimmedVideoId = item.videoId.trim();
      if (!YOUTUBE_API_KEY || !trimmedVideoId) {
        return buildFallbackItem(item, true);
      }

      const url = new URL("https://www.googleapis.com/youtube/v3/videos");
      url.searchParams.set("part", "snippet,contentDetails");
      url.searchParams.set("id", trimmedVideoId);
      url.searchParams.set("key", YOUTUBE_API_KEY);

      try {
        const response = await fetch(url.toString());
        if (!response.ok) {
          console.error("YouTube API failed", await response.text());
          return buildFallbackItem(item, true);
        }

        const payload = await response.json();
        const video = Array.isArray(payload?.items) ? payload.items[0] : null;
        if (!video) {
          return buildFallbackItem(item, true);
        }

        return {
          title: item.title,
          channel: item.channel,
          time: item.time,
          videoId: String(video.id ?? trimmedVideoId),
          duration: isoDurationToHuman(video.contentDetails?.duration ?? ""),
          thumbnails: video.snippet?.thumbnails?.medium ?? {},
        };
      } catch (error) {
        console.error("YouTube videos.list fetch error", error);
        return buildFallbackItem(item, true);
      }
    })
  );

  return results;
}

function isoDurationToHuman(raw: string | null): string {
  if (!raw) return "";
  const matches = Array.from(raw.matchAll(/(\d+)([HMS])/g));
  if (!matches.length) return "";
  let hours = 0,
    minutes = 0,
    seconds = 0;
  matches.forEach((match) => {
    const value = Number(match[1]);
    switch (match[2]) {
      case "H":
        hours = value;
        break;
      case "M":
        minutes = value;
        break;
      case "S":
        seconds = value;
        break;
    }
  });
  if (hours) {
    return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(
      2,
      "0"
    )}:${String(seconds).padStart(2, "0")}`;
  }
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function buildFallbackItem(item: ParsedItem, dropId = false): IntakeItem {
  return {
    title: item.title,
    channel: item.channel,
    time: item.time,
    videoId: dropId ? "" : item.videoId.trim(),
    duration: "",
    thumbnails: {},
  };
}
