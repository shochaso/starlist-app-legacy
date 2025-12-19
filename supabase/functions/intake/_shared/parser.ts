export interface GroqItem {
  title?: string;
  channel?: string;
  time?: string | null;
  videoId?: string | null;
}

export interface ParsedItem {
  title: string;
  channel: string;
  time: string | null;
  videoId: string;
}

const noisePatterns = [
  /[\u00A0\r]/g,
  /(\d+(\.\d+)?)(万|K)?\s*回視聴/g,
  /【[^】]+】/g,
  /[\p{Emoji_Presentation}\p{Emoji}\p{Emoji_Modifier_Base}]/gu,
];

function cleanText(value?: string): string {
  let result = value ?? "";
  noisePatterns.forEach((pattern) => {
    result = result.replace(pattern, "");
  });
  return result.replace(/\s+/g, " ").trim();
}

function normalizeDuration(raw?: string | null): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  const match = trimmed.match(/(\d{1,2}:)?\d{1,2}:\d{2}/);
  if (match) {
    return match[0];
  }
  if (/^\d+分$/.test(trimmed)) {
    return trimmed;
  }
  return null;
}

export function parseGroqItems(items: GroqItem[]): ParsedItem[] {
  return items
    .map((item) => ({
      title: cleanText(item.title),
      channel: cleanText(item.channel),
      time: normalizeDuration(item.time),
      videoId: (item.videoId ?? "").trim(),
    }))
    .filter((item) => item.title && item.channel);
}

export function safeParseGroqResponse(content: unknown): GroqItem[] | null {
  if (typeof content !== "object" || content === null) return null;
  const items = (content as { items?: unknown }).items;
  if (!Array.isArray(items)) return null;
  const parsed: GroqItem[] = [];
  for (const item of items) {
    if (
      typeof item === "object" &&
      item !== null &&
      typeof (item as GroqItem).title === "string" &&
      typeof (item as GroqItem).channel === "string"
    ) {
      parsed.push({
        title: (item as GroqItem).title,
        channel: (item as GroqItem).channel,
        time: (item as GroqItem).time,
        videoId: (item as GroqItem).videoId,
      });
    }
  }
  return parsed.length ? parsed : null;
}







