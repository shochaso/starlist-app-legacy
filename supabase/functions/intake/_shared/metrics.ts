import { createClient, type SupabaseClient } from "supabase-js";
import {
  buildMetricRecord,
  type IntakeMetricPayload,
} from "./lib/metrics-core.ts";
import type { IntakeConfig } from "./config.ts";

let supabaseClient: SupabaseClient | null = null;
let metricsEnabled = false;

export function initIntakeMetrics(config: IntakeConfig): void {
  metricsEnabled = config.metricsEnabled &&
    Boolean(config.supabaseUrl && config.supabaseServiceRoleKey);
  if (!metricsEnabled) return;

  supabaseClient = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);
}

export async function logIntakeMetric(
  payload: IntakeMetricPayload,
): Promise<void> {
  if (!metricsEnabled || !supabaseClient) return;
  try {
    const record = await buildMetricRecord(payload);
    await supabaseClient.from("intake_metrics").insert(record);
  } catch (error) {
    console.error("Failed to record intake metric", error);
  }
}



