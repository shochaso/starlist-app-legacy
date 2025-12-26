import Groq from "groq-sdk";

const apiKey = process.env.GROQ_API_KEY ?? "";
const isProd = process.env.NODE_ENV === "production";
const isProdBuild = process.env.NEXT_PHASE === "phase-production-build";

if (!apiKey && !(isProd || isProdBuild)) {
  console.warn("GROQ_API_KEY is not configured. Groq completions will fail.");
}

const client = apiKey ? new Groq({ apiKey }) : null;

export async function runGroqCompletion(prompt: string): Promise<unknown | null> {
  if (!client) {
    return null;
  }

  // Add timeout to prevent hanging requests
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

  try {
    const response = await client.chat.completions.create({
      model: "llama-3.1-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.1,
      response_format: { type: "json_object" },
    }, {
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response.choices?.[0]?.message?.content;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error('Groq API request timed out after 30 seconds');
    }
    throw error;
  }
}
