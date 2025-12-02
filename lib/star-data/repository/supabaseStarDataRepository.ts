import type { SupabaseClient } from "@supabase/supabase-js";

import { GET_ITEMS_RPC, GET_PACK_RPC, GET_SUMMARY_RPC } from "../requests/rpcNames";
import { buildItemsParams, buildPackParams, buildSummaryParams } from "../requests/rpcParams";
import type { StarDataRepository } from "./starDataRepository";
import type { StarDataItem } from "../models/starDataItem";
import type { StarDataPack } from "../models/starDataPack";
import type { StarDataSummary } from "../models/starDataSummary";

export class SupabaseStarDataRepository implements StarDataRepository {
  constructor(private options: { client: SupabaseClient }) {}

  private get client(): SupabaseClient {
    return this.options.client;
  }

  async fetchItems(params: {
    username: string;
    date: string;
    category?: string;
    genre?: string;
  }): Promise<StarDataItem[]> {
    const rpcParams = buildItemsParams({
      username: params.username,
      date: new Date(params.date),
      category: params.category,
      genre: params.genre,
    });
    const { data, error } = await this.client.rpc(GET_ITEMS_RPC, rpcParams);
    if (error) {
      throw error;
    }
    const rows = Array.isArray(data) ? data : [];
    return rows.map((row) => mapStarDataItem(row));
  }

  async fetchPack(packId: string): Promise<StarDataPack> {
    const { data, error } = await this.client.rpc(GET_PACK_RPC, buildPackParams({ packId }));
    if (error) {
      throw error;
    }
    const payload = Array.isArray(data) ? data[0] : data;
    if (!payload) {
      throw new Error("StarDataPack not found");
    }
    return mapStarDataPack(payload);
  }

  async fetchSummary(username: string): Promise<StarDataSummary> {
    const { data, error } = await this.client.rpc(GET_SUMMARY_RPC, buildSummaryParams({ username }));
    if (error) {
      throw error;
    }
    const payload = Array.isArray(data) ? data[0] : data;
    if (!payload) {
      throw new Error("StarDataSummary not found");
    }
    return mapStarDataSummary(payload);
  }

  async hideItem(itemId: string): Promise<void> {
    const { error } = await this.client
      .from("star_data_items")
      .update({
        is_hidden: true,
        hidden_at: new Date().toISOString(),
      })
      .eq("id", itemId);
    if (error) {
      throw error;
    }
  }
}

function mapStarDataItem(record: any): StarDataItem {
  const metadata = extractMetadata(record);
  const thumbnailUrl = resolveThumbnailUrl(record, metadata);
  return {
    id: String(record.id ?? ""),
    starId: String(record.star_id ?? record.username ?? ""),
    date: String(record.occurred_at ?? record.date ?? ""),
    category: String(record.category ?? ""),
    genre: String(record.genre ?? ""),
    title: String(record.title ?? ""),
    subtitle: String(record.subtitle ?? ""),
    source: String(record.source ?? ""),
    createdAt: String(record.created_at ?? record.createdAt ?? ""),
    isHidden: Boolean(record.is_hidden ?? false),
    thumbnailUrl,
    metadata,
    extra: record.raw_payload ?? undefined,
  };
}

function mapStarDataPack(record: any): StarDataPack {
  const items = Array.isArray(record.items) ? record.items : [];
  return {
    packId: String(record.pack_id ?? record.packId ?? ""),
    createdAt: String(record.created_at ?? record.createdAt ?? new Date().toISOString()),
    items: items.map(mapStarDataItem),
  };
}

function mapStarDataSummary(record: any): StarDataSummary {
  return {
    dailyCount: Number(record.daily_count ?? record.dailyCount ?? 0),
    weeklyCount: Number(record.weekly_count ?? record.weeklyCount ?? 0),
    monthlyCount: Number(record.monthly_count ?? record.monthlyCount ?? 0),
    latestCategories: Array.isArray(record.latest_categories)
      ? record.latest_categories.map((cat: unknown) => String(cat))
      : Array.isArray(record.latestCategories)
      ? record.latestCategories.map((cat: unknown) => String(cat))
      : [],
  };
}

type UnknownRecord = Record<string, unknown>;

function extractMetadata(record: any): UnknownRecord | undefined {
  const candidate =
    record.metadata ??
    record.raw_payload ??
    record.metadata_payload ??
    record.rawPayload ??
    (record.extra ?? undefined);

  if (candidate && typeof candidate === "object" && !Array.isArray(candidate)) {
    return candidate as UnknownRecord;
  }

  return undefined;
}

function resolveThumbnailUrl(
  record: any,
  metadata?: UnknownRecord,
): string | undefined {
  const candidates = [
    record.thumbnailUrl,
    record.thumbnail_url,
    record.thumbnail,
    metadata?.thumbnail_url,
    metadata?.thumbnailUrl,
    metadata?.thumbnail,
  ];

  for (const value of candidates) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value;
    }
  }

  return undefined;
}
