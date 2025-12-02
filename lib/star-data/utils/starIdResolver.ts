export function resolveStarId(username: string): string {
  const normalized = username.trim().toLowerCase();
  if (!normalized) {
    return "star_hanayama_mizuki";
  }
  if (normalized === "hanayama-mizuki" || normalized === "花山瑞樹") {
    return "star_hanayama_mizuki";
  }
  if (normalized === "kato-junichi" || normalized === "加藤純一") {
    return "star_kato_junichi";
  }
  const resolved = normalized.replace(/-/g, "_");
  return `star_${resolved.replace(/[^a-z0-9_]/g, "_")}`;
}
