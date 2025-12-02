import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleIntakeRequest } from "./_shared/handler.ts";
import { RateLimitError } from "./_shared/rate.ts";

serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: true, message: "Method not allowed" }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Allow": "POST, OPTIONS"
        }
      }
    );
  }

  try {
    const response = await handleIntakeRequest(req);
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  } catch (err) {
    console.error("Intake error:", err);
    
    // Handle RateLimitError specifically
    if (err instanceof RateLimitError) {
      const rateLimitError = err;
      return new Response(
        JSON.stringify({
          error: true,
          message: "Rate limit exceeded",
          retryAfterSeconds: rateLimitError.retryAfterSeconds,
          limitPerMinute: rateLimitError.limitPerMinute,
          limitPerDay: rateLimitError.limitPerDay,
          window: rateLimitError.window,
        }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": rateLimitError.retryAfterSeconds.toString(),
          }
        }
      );
    }
    
    return new Response(
      JSON.stringify({ error: true, message: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
