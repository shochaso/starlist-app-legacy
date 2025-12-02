export function normalizeDate(date: Date): string {
  const normalized = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  return normalized.toISOString().split("T")[0];
}
