import { NextResponse } from "next/server";
import { runGroqCompletion } from "../../lib/groqClient";
import { parseYoutubeOCR, GroqItem } from "../../lib/parseYoutubeOCR";
import { youtubeEnrich } from "../../lib/youtubeEnrich";
import { IntakeResponse } from "../../types/youtube-intake";

const YOUTUBE_PROMPT = `
You are an assistant that extracts YouTube watch history from OCR.
OCR:
{OCR_PLACEHOLDER}

Return strict JSON:
{
  "items": [
    {
      "title": "...",
      "channel": "...",
      "time": "12:41" or null,
      "videoId": "" or null
    }
  ]
}
`;

function buildErrorResponse(message: string, status: number, raw?: string) {
  const body = { error: true, message, raw } as Record<string, unknown>;
  return NextResponse.json(body, { status });
}

function safeParseGroqResponse(content: unknown): GroqItem[] | null {
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
        time: (item as GroqItem).time ?? null,
        videoId: (item as GroqItem).videoId ?? "",
      });
    }
  }
  return parsed.length ? parsed : null;
}

/**
 * DEPRECATED: Use Supabase Edge Function instead
 *
 * Recommended: Use /supabase/functions/intake instead of this Next.js API.
 * The Edge Function provides better performance, caching, and reliability.
 *
 * Flutter integration (recommended):
 * final res = await http.post(
 *   Uri.parse("https://your-supabase-project.supabase.co/functions/v1/intake"),
 *   headers: {
 *     "Content-Type": "application/json",
 *     "Authorization": "Bearer $SUPABASE_ANON_KEY"
 *   },
 *   body: jsonEncode({"ocrText": extractedText}),
 * );
 *
 * Legacy Next.js API integration:
 * final res = await http.post(
 *   Uri.parse("https://your-domain/api/youtube-intake"),
 *   headers: {"Content-Type": "application/json"},
 *   body: jsonEncode({"ocrText": extractedText}),
 * );
 * final data = jsonDecode(res.body);
 * print(data["items"]);
 */
export async function POST(req: Request) {
  const groqKey = process.env.GROQ_API_KEY;
  if (!groqKey) {
    return buildErrorResponse("GROQ_API_KEY is not configured.", 401);
  }

  const youtubeKey = process.env.YOUTUBE_API_KEY;
  if (!youtubeKey) {
    return buildErrorResponse("YOUTUBE_API_KEY is not configured.", 401);
  }

  let body: { ocrText?: string };
  try {
    body = await req.json();
  } catch (error) {
    return buildErrorResponse(
      "Request JSON parse failed",
      400,
      (error as Error).message
    );
  }

  if (!body?.ocrText) {
    return buildErrorResponse("ocrText field is required.", 400);
  }

  const prompt = YOUTUBE_PROMPT.replace("{OCR_PLACEHOLDER}", body.ocrText);

  let groqPayload: unknown;
  try {
    groqPayload = await runGroqCompletion(prompt);
  } catch (error) {
    return buildErrorResponse(
      "Groq completion failed",
      502,
      (error as Error).message
    );
  }

  const structured = safeParseGroqResponse(groqPayload);
  if (!structured) {
    return buildErrorResponse(
      "Unexpected Groq response",
      502,
      typeof groqPayload === "string"
        ? groqPayload
        : JSON.stringify(groqPayload ?? {})
    );
  }

  const parsedItems = parseYoutubeOCR(structured);
  const enriched = await youtubeEnrich(parsedItems);

  const payload: IntakeResponse = {
    items: enriched,
  };

  return NextResponse.json(payload);
}
