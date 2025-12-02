export interface IntakeItem {
  title: string;
  channel: string;
  time: string | null;
  videoId: string;
  duration: string;
  thumbnails: Record<string, unknown>;
}

export interface IntakeResponse {
  items: IntakeItem[];
}
