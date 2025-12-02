const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";

export async function runGroqCompletion(prompt: string): Promise<unknown> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    throw new Error("GROQ_API_KEY is not configured");
  }

  const body = {
    model: "llama-3.1-70b-versatile",
    messages: [{ role: "user", content: prompt }],
    temperature: 0.1,
    response_format: { type: "json_object" },
  };

  const response = await fetch(GROQ_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Groq API failed: ${message}`);
  }

  const payload = await response.json();
  return payload.choices?.[0]?.message?.content;
}
