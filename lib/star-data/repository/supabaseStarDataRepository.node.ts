import { createServerSupabaseClient } from "../../supabase/serverClient";
import { SupabaseStarDataRepository } from "./supabaseStarDataRepository";

export function createSupabaseStarDataRepository() {
  const client = createServerSupabaseClient();
  return new SupabaseStarDataRepository({ client });
}
