import { normalizeDate } from "./normalizeDate";

export function buildPackId(username: string, date: Date): string {
  const name = username.trim();
  const datePortion = normalizeDate(date);
  return `${name}::${datePortion}`;
}
