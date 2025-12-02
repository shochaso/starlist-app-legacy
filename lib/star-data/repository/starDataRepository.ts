import type { StarDataItem } from "../models/starDataItem";
import type { StarDataPack } from "../models/starDataPack";
import type { StarDataSummary } from "../models/starDataSummary";

export interface StarDataRepository {
  fetchItems(params: {
    username: string;
    date: string;
    category?: string;
    genre?: string;
  }): Promise<StarDataItem[]>;

  fetchPack(packId: string): Promise<StarDataPack>;

  fetchSummary(username: string): Promise<StarDataSummary>;

  hideItem(itemId: string): Promise<void>;
}
