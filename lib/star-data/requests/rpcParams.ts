import { normalizeDate } from "../utils/normalizeDate";
import { resolveStarId } from "../utils/starIdResolver";

export interface ItemsParams {
  username: string;
  date: Date;
  category?: string;
  genre?: string;
}

export interface PackParams {
  packId: string;
}

export interface SummaryParams {
  username: string;
}

export function buildItemsParams(params: ItemsParams): Record<string, unknown> {
  return {
    p_star_id: resolveStarId(params.username),
    p_occurred_at: normalizeDate(params.date),
    p_category: params.category ?? null,
    p_genre: params.genre ?? null,
  };
}

export function buildPackParams(params: PackParams): Record<string, unknown> {
  return {
    p_pack_id: params.packId,
  };
}

export function buildSummaryParams(params: SummaryParams): Record<string, unknown> {
  return {
    p_star_id: resolveStarId(params.username),
  };
}
