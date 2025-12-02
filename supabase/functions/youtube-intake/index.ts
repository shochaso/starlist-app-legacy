import { serve } from "https://deno.land/std@0.191.0/http/server.ts";
import { handleYoutubeIntakeRequest } from "./_shared/youtubeIntakeHandler.ts";

serve(async (req) => {
  const headers = { "Content-Type": "application/json; charset=utf-8" };
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: true, message: "Method not allowed", raw: "" }),
      { status: 405, headers }
    );
  }

  try {
    return await handleYoutubeIntakeRequest(req);
  } catch (err) {
    console.error("youtube-intake edge error", err);
    return new Response(
      JSON.stringify({ error: true, message: "Internal error", raw: "" }),
      { status: 500, headers }
    );
  }
});
