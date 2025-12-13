import Image from "next/image";
import { buildPackId } from "@/lib/star-data/utils/buildPackId";
import { createSupabaseStarDataRepository } from "@/lib/star-data/repository/supabaseStarDataRepository.node";
import type { StarDataItem } from "@/lib/star-data/models/starDataItem";

type PackSectionProps = {
  username: string;
  date: Date;
};

export default async function PackSection({ username, date }: PackSectionProps) {
  try {
    const repository = createSupabaseStarDataRepository();
    const pack = await repository.fetchPack(buildPackId(username, date));
    const items = pack.items ?? [];

    if (items.length === 0) {
      return (
        <section className="rounded-3xl border border-dashed border-slate-200 bg-white/80 p-6 text-center text-sm text-slate-500">
          <p className="font-semibold text-slate-600">この日のデータはまだ用意されていません。</p>
        </section>
      );
    }

    const primaryItem = items[0];
    const additionalItems = Math.max(0, items.length - 1);
    const displayedItems = items.slice(0, 3);
    const isPublicPack = items.some(isPublicItem);
    const packDateLabel = formatPackDateLabel(pack.createdAt ?? primaryItem?.date);

    return (
      <section className="space-y-5">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.5em] text-slate-400">
              TODAY DATA PACK
            </p>
            <div className="mt-1 text-3xl font-semibold text-slate-900 leading-tight">
              {primaryItem?.title ?? "今日のマイデータ"}
            </div>
            {packDateLabel && (
              <p className="text-sm text-slate-500">{packDateLabel}</p>
            )}
          </div>
          <div className="flex flex-col items-end gap-1">
            <span
              className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.3em] ${
                isPublicPack
                  ? "border-emerald-100 bg-emerald-50 text-emerald-700"
                  : "border-rose-100 bg-rose-50 text-rose-700"
              }`}
            >
              {isPublicPack ? "公開" : "メンバープラン"}
            </span>
            {isPublicPack && (
              <p className="text-xs text-slate-500">無料会員でも閲覧可能</p>
            )}
          </div>
        </div>

        <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-[0px_20px_60px_rgba(15,23,42,0.12)]">
          <div className="flex flex-wrap items-start gap-4">
            <div className="relative h-28 w-28 shrink-0 overflow-hidden rounded-2xl bg-slate-100">
              {renderThumbnail(primaryItem, 112)}
            </div>
            <div className="flex min-w-0 flex-1 flex-col gap-2">
              <p className="text-lg font-semibold text-slate-900">
                {primaryItem?.title ?? "タイトルなしのデータ"}
              </p>
              {primaryItem?.subtitle && (
                <p className="text-sm text-slate-500">{primaryItem.subtitle}</p>
              )}
              <p className="text-sm text-slate-500">{formatItemMeta(primaryItem)}</p>
              <p className="text-xs text-slate-400">
                {additionalItems > 0
                  ? `他 ${additionalItems} 件のデータを含むパック`
                  : "この日のデータだけをまとめたパックです"}
              </p>
            </div>
          </div>

          <div className="mt-6 space-y-3">
            {displayedItems.map((item) => (
              <article
                key={item.id}
                className="flex items-center gap-3 rounded-2xl border border-slate-100 bg-slate-50/70 p-3"
              >
                <div className="h-12 w-12 shrink-0 overflow-hidden rounded-xl bg-slate-100">
                  {renderThumbnail(item, 48)}
                </div>
                <div className="flex flex-1 flex-col gap-0.5">
                  <p className="text-sm font-semibold text-slate-900">
                    {item.title || "タイトル未設定のデータ"}
                  </p>
                  <p className="text-xs text-slate-500">
                    {formatItemMeta(item)} ・ {formatRelativeTime(item.date)}
                  </p>
                </div>
              </article>
            ))}
            {items.length > displayedItems.length && (
              <p className="text-xs text-slate-400">
                他 {items.length - displayedItems.length} 件のデータが含まれています
              </p>
            )}
          </div>
        </div>
      </section>
    );
  } catch (error) {
    console.error("Failed to load pack", error);
    return (
      <section className="rounded-3xl border border-red-100 bg-red-50/70 p-6 text-sm text-red-600">
        <p className="font-semibold">パックの読み込み中に問題が発生しました。</p>
      </section>
    );
  }
}

type StarDataMetadata = Record<string, unknown>;

function formatPackDateLabel(value?: string): string {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("ja-JP", {
    month: "long",
    day: "numeric",
  }).format(date);
}

function formatItemMeta(item?: StarDataItem): string {
  if (!item) return "情報なし";

  const metaParts = [];
  if (item.source?.trim()) {
    metaParts.push(item.source.trim());
  }

  const metadata = item.metadata;
  const duration = getStringMetadata(metadata, "duration");
  if (duration) {
    metaParts.push(duration);
  }

  const platform = getStringMetadata(metadata, "platform");
  if (platform) {
    metaParts.push(platform);
  }

  const store = getStringMetadata(metadata, "store");
  if (store) {
    metaParts.push(store);
  }

  const price = metadata ? metadata["price"] : undefined;
  if (typeof price === "number") {
    metaParts.push(`¥${price.toLocaleString()}`);
  }

  const match = getStringMetadata(metadata, "match");
  if (match) {
    metaParts.push(match);
  }

  return metaParts.length > 0 ? metaParts.join(" ・ ") : "情報なし";
}

function getStringMetadata(
  metadata: StarDataMetadata | undefined,
  key: string,
): string | undefined {
  const value = metadata?.[key];
  if (typeof value === "string" && value.trim().length > 0) {
    return value;
  }
  return undefined;
}

function formatRelativeTime(value?: string): string {
  if (!value) return "";
  const timestamp = Date.parse(value);
  if (Number.isNaN(timestamp)) return "";
  const diffMs = Math.max(0, Date.now() - timestamp);
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) {
    return "たった今";
  }
  if (minutes < 60) {
    return `${minutes}分前`;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return `${hours}時間前`;
  }
  const days = Math.floor(hours / 24);
  if (days === 1) {
    return "昨日";
  }
  return `${days}日前`;
}

function isPublicItem(item: StarDataItem): boolean {
  const normalized = (value?: string): string => (value ?? "").toLowerCase();
  const metadataSource = getStringMetadata(item.metadata, "source");
  return (
    normalized(item.category) === "youtube" ||
    normalized(item.source).includes("youtube") ||
    normalized(metadataSource).includes("youtube")
  );
}

function getThumbnailUrl(item?: StarDataItem): string | undefined {
  if (!item) return undefined;
  if (item.thumbnailUrl?.trim()) {
    return item.thumbnailUrl;
  }
  if (item.metadata) {
    const thumbnail =
      getStringMetadata(item.metadata, "thumbnail_url") ??
      getStringMetadata(item.metadata, "thumbnailUrl") ??
      getStringMetadata(item.metadata, "thumbnail");
    if (thumbnail) {
      return thumbnail;
    }
  }
  return undefined;
}

function renderThumbnail(item?: StarDataItem, size = 112) {
  const src = getThumbnailUrl(item);
  if (!src) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-slate-100">
        <span className="text-xs font-semibold text-slate-500">NO IMAGE</span>
      </div>
    );
  }

  return (
    <Image
      src={src}
      alt={item?.title ?? "マイデータのサムネイル"}
      width={size}
      height={size}
      loading="lazy"
      decoding="async"
      sizes={`${size}px`}
      className="h-full w-full object-cover"
      unoptimized
    />
  );
}
