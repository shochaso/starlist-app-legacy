import {
  getEnv,
  getEnvBool,
  getEnvNumber,
} from "../../_shared/env.ts";

export interface IntakeConfig {
  groqApiKey: string;
  youtubeApiKey: string;
  rateLimitDisabled: boolean;
  rateLimitPerMinute: number;
  rateLimitPerDay: number;
  metricsEnabled: boolean;
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  secondaryLLM?: {
    provider: string;
    apiKey: string;
  };
  environment: string;
}

let cachedConfig: IntakeConfig | null = null;

export function getIntakeConfig(): IntakeConfig {
  if (cachedConfig) return cachedConfig;

  const groqApiKey = getEnv("GROQ_API_KEY");
  const youtubeApiKey = getEnv("YOUTUBE_API_KEY");
  const rateLimitDisabled = getEnvBool("INTAKE_RATE_LIMIT_DISABLED", false);
  const rateLimitPerMinute = getEnvNumber(
    "INTAKE_RATE_LIMIT_PER_MINUTE",
    5,
  );
  const rateLimitPerDay = getEnvNumber("INTAKE_RATE_LIMIT_PER_DAY", 200);
  const metricsEnabled = getEnvBool("INTAKE_METRICS_ENABLED", false);
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (metricsEnabled && (!supabaseUrl || !supabaseServiceRoleKey)) {
    console.warn(
      "INTAKE_METRICS_ENABLED is true but SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing",
    );
  }

  const secondaryProvider = Deno.env.get("SECONDARY_LLM_PROVIDER") ?? "";
  const secondaryKey = Deno.env.get("SECONDARY_LLM_API_KEY") ?? "";
  const secondaryLLM = secondaryProvider && secondaryKey
    ? { provider: secondaryProvider, apiKey: secondaryKey }
    : undefined;

  const environment = Deno.env.get("NODE_ENV") ?? "production";

  cachedConfig = {
    groqApiKey,
    youtubeApiKey,
    rateLimitDisabled,
    rateLimitPerMinute,
    rateLimitPerDay,
    metricsEnabled,
    supabaseUrl,
    supabaseServiceRoleKey,
    secondaryLLM,
    environment,
  };

  return cachedConfig;
}


