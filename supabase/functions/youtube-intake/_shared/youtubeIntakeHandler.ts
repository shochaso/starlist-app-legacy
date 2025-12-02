import { IntakeResponse } from "../_shared/youtube.ts";
import { runGroqCompletion } from "../_shared/groq.ts";
import {
  parseGroqItems,
  safeParseGroqResponse,
} from "../_shared/parser.ts";
import { enrichYoutubeItems } from "../_shared/youtube.ts";

const promptTemplate = `
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

export async function handleYoutubeIntakeRequest(req: Request): Promise<Response> {
  const headers = { "Content-Type": "application/json; charset=utf-8" };
  let payload: { ocrText?: string };
  try {
    payload = await req.json();
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: true,
        message: "Request JSON parse failed",
        raw: (error as Error).message,
      }),
      { status: 400, headers }
    );
  }

  if (!payload?.ocrText) {
    return new Response(
      JSON.stringify({
        error: true,
        message: "ocrText field is required.",
        raw: "",
      }),
      { status: 400, headers }
    );
  }

  const prompt = promptTemplate.replace("{OCR_PLACEHOLDER}", payload.ocrText);

  let groqResult: unknown;
  try {
    groqResult = await runGroqCompletion(prompt);
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: true,
        message: "Groq completion failed",
        raw: (error as Error).message,
      }),
      { status: 502, headers }
    );
  }

  const groqItems = safeParseGroqResponse(groqResult);
  if (!groqItems) {
    return new Response(
      JSON.stringify({
        error: true,
        message: "Unexpected Groq response",
        raw: typeof groqResult === "string" ? groqResult : JSON.stringify(groqResult ?? {}),
      }),
      { status: 502, headers }
    );
  }

  const parsed = parseGroqItems(groqItems);
  const enriched: IntakeResponse = await enrichYoutubeItems(parsed);

  return new Response(JSON.stringify(enriched), { status: 200, headers });
}
