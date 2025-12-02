export interface StarDataItem {
  id: string;
  starId: string;
  date: string; // ISO8601 string
  category: string;
  genre: string;
  title: string;
  subtitle: string;
  source: string;
  createdAt: string; // ISO8601 string
  isHidden: boolean;
  thumbnailUrl?: string;
  metadata?: Record<string, unknown>;
  extra?: Record<string, unknown>;
}
