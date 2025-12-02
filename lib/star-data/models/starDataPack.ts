import type { StarDataItem } from "./starDataItem";

export interface StarDataPack {
  packId: string;
  items: StarDataItem[];
  createdAt: string; // UTC timestamp
}
