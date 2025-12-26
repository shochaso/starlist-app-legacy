"use client";

import React, { useMemo, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Separator } from "@/components/ui/separator";
import { Search } from "lucide-react";

type ItemType = "youtube" | "shopping" | "music" | "receipt";

type YoutubePreview = {
  title: string;
  channel: string;
};

type GenreKey =
  | "all"
  | "video_variety"
  | "video_bgm"
  | "video_asmr"
  | "shopping_work"
  | "music_work";

type DataItem = {
  id: string;
  type: ItemType;
  service: string;
  title: string;
  description: string;
  createdAgo: string;
  totalCount?: number;
  remainingCount?: number;
  previews?: YoutubePreview[];
  genres?: GenreKey[];
};

type ColorMode = "dark" | "light";

const STAR = {
  name: "さとう ゆう",
  handle: "yu_satou",
};

const ITEMS: DataItem[] = [
  {
    id: "yt-pack-1",
    type: "youtube",
    service: "YouTube",
    title: "YouTube視聴動画",
    description: "今日視聴した動画のまとめ",
    createdAgo: "3時間前",
    totalCount: 12,
    remainingCount: 9,
    previews: [
      { title: "夜更かしバラエティ", channel: "夜ふかしTV" },
      { title: "作業用BGMまとめ", channel: "Lofi_Ch" },
      { title: "ASMRでひと休み", channel: "ゆる眠ちゃん" },
    ],
    genres: ["video_variety", "video_bgm", "video_asmr"],
  },
  {
    id: "shopping-1",
    type: "shopping",
    service: "Amazon",
    title: "3つの商品を購入",
    description:
      "ノートPCスタンド / ブルーライトカット眼鏡 / ケーブル収納ケース",
    createdAgo: "昨日",
    genres: ["shopping_work"],
  },
  {
    id: "music-1",
    type: "music",
    service: "Spotify",
    title: "3曲を視聴",
    description:
      "ローファイ / シティポップ / アンビエントをシャッフル再生",
    createdAgo: "5時間前",
    genres: ["music_work"],
  },
];

const TYPE_LABEL: Record<"all" | ItemType, string> = {
  all: "すべて",
  youtube: "動画（YouTube）",
  shopping: "ショッピング",
  music: "音楽",
  receipt: "レシート",
};

const GENRE_LABEL: Record<GenreKey, string> = {
  all: "すべて",
  video_variety: "バラエティ",
  video_bgm: "作業用BGM",
  video_asmr: "ASMR",
  shopping_work: "仕事道具",
  music_work: "作業用プレイリスト",
};

const GENRES_BY_TYPE: Record<ItemType, GenreKey[]> = {
  youtube: ["video_variety", "video_bgm", "video_asmr"],
  shopping: ["shopping_work"],
  music: ["music_work"],
  receipt: [],
};

function Chip({
  children,
  className = "",
  ...rest
}: React.HTMLAttributes<HTMLSpanElement> & { children: React.ReactNode }) {
  return (
    <span
      className={[
        "inline-flex items-center rounded-full px-2.5 py-1 text-xs border",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      {...rest}
    >
      {children}
    </span>
  );
}

function TypeFilterChip({
  value,
  active,
  onClick,
}: {
  value: "all" | ItemType;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        "rounded-full border px-3 py-1 text-xs transition-colors",
        active
          ? "border-slate-200 bg-slate-100 text-slate-900"
          : "border-slate-600 bg-transparent text-slate-300 hover:bg-slate-800",
      ].join(" ")}
    >
      {TYPE_LABEL[value]}
    </button>
  );
}

function GenreFilterChip({
  value,
  active,
  onClick,
}: {
  value: GenreKey;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        "rounded-full border px-3 py-1 text-xs transition-colors",
        active
          ? "border-slate-200 bg-slate-100 text-slate-900"
          : "border-slate-600 bg-transparent text-slate-300 hover:bg-slate-800",
      ].join(" ")}
    >
      {GENRE_LABEL[value]}
    </button>
  );
}

function PackCard({
  item,
  mode,
  onViewDetail,
}: {
  item: DataItem;
  mode: ColorMode;
  onViewDetail: (item: DataItem) => void;
}) {
  const previews = item.previews ?? [];
  const isYoutube = item.type === "youtube";
  const totalCount = isYoutube ? item.totalCount ?? previews.length : undefined;
  const remaining = isYoutube
    ? item.remainingCount ?? Math.max((totalCount ?? previews.length) - previews.length, 0)
    : 0;

  const chipLabelByType: Record<ItemType, string> = {
    youtube: "YouTube視聴",
    shopping: "ショッピング",
    music: "音楽",
    receipt: "レシート",
  };

  const headerText =
    isYoutube && totalCount != null ? `YouTube視聴動画 ${totalCount}本` : item.title;

  const descriptionLines = isYoutube
    ? []
    : item.description
        .split(/[／/]/)
        .map((s) => s.trim())
        .filter(Boolean);

  const isDark = mode === "dark";

  const firstGenreLabel =
    item.genres && item.genres.length > 0 ? GENRE_LABEL[item.genres[0]] : undefined;

  return (
    <Card
      className={
        isDark
          ? "bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden h-full"
          : "bg-white border border-slate-200 rounded-3xl overflow-hidden h-full"
      }
    >
      <CardContent className="flex h-full flex-col p-4 sm:p-5">
        <div className="flex items-center justify-between gap-3 mb-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-cyan-300 via-violet-400 to-pink-400" />
            <div className="flex flex-col items-end text-right">
              <span
                className={
                  isDark ? "text-sm font-semibold text-slate-50" : "text-sm font-semibold text-slate-900"
                }
              >
                {STAR.name}
              </span>
              <span className={isDark ? "text-xs text-slate-400" : "text-xs text-slate-500"}>
                @{STAR.handle}
              </span>
            </div>
          </div>
          <Chip
            className={
              isDark
                ? "border-slate-600 bg-slate-800 text-slate-100 text-xs px-3 py-1 rounded-full"
                : "border-slate-300 bg-slate-100 text-slate-700 text-xs px-3 py-1 rounded-full"
            }
          >
            {chipLabelByType[item.type]}
          </Chip>
        </div>
        <div className="mt-1 flex-1">
          <div
            className={
              isDark
                ? "rounded-2xl bg-slate-800/80 border border-slate-700 px-4 py-4 text-slate-50 h-full flex flex-col"
                : "rounded-2xl bg-slate-50 border border-slate-200 px-4 py-4 text-slate-900 h-full flex flex-col"
            }
          >
            <div className="mb-2">
              <span
                className={
                  isDark
                    ? "inline-flex items-center rounded-full bg-slate-900/60 px-3 py-1 text-[10px] font-medium tracking-[0.12em] uppercase text-slate-300"
                    : "inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-[10px] font-medium tracking-[0.12em] uppercase text-slate-500"
                }
              >
                TODAY DATA PACK
              </span>
            </div>
            <div className="mb-4">
              <div className="text-lg sm:text-xl font-bold leading-snug">{headerText}</div>
            </div>
            {isYoutube ? (
              <div className="space-y-2 text-xs sm:text-sm">
                {previews[0] && (
                  <div className="flex flex-col">
                    <span className="leading-tight">{previews[0].title}</span>
                    <span
                      className={
                        isDark ? "text-[11px] text-slate-300" : "text-[11px] text-slate-500"
                      }
                    >
                      {"　" + previews[0].channel}
                    </span>
                  </div>
                )}
              </div>
            ) : (
              <div className="flex-1 flex flex-col text-xs sm:text-sm">
                <div className="space-y-2">
                  {descriptionLines.slice(0, 1).map((text) => (
                    <div key={text} className="flex flex-col">
                      <span className="leading-tight blur-sm">{text}</span>
                    </div>
                  ))}
                </div>
                {descriptionLines.length > 1 && (
                  <div className="mt-auto flex justify-end pt-4">
                    <button
                      type="button"
                      className={
                        (isDark
                          ? "bg-slate-900/60 text-slate-100 border border-slate-600"
                          : "bg-slate-100 text-slate-700 border border-slate-300") +
                        " inline-flex items-center gap-1 rounded-full px-3 py-1.5 text-[11px] font-medium"
                      }
                    >
                      <span className="text-base leading-none">＋</span>
                      <span>
                        他{descriptionLines.length - 1}
                        {item.type === "shopping"
                          ? "件の商品を購入"
                          : item.type === "music"
                          ? "曲を視聴"
                          : "件のデータ"}
                      </span>
                    </button>
                  </div>
                )}
              </div>
            )}
            {isYoutube && remaining > 0 && (
              <div className="mt-auto flex justify-end pt-4">
                <button
                  type="button"
                  className={
                    (isDark
                      ? "bg-slate-900/60 text-slate-100 border border-slate-600"
                      : "bg-slate-100 text-slate-700 border border-slate-300") +
                    " inline-flex items-center gap-1 rounded-full px-3 py-1.5 text-[11px] font-medium"
                  }
                >
                  <span className="text-base leading-none">＋</span>
                  <span>他{remaining}本の動画を視聴</span>
                </button>
              </div>
            )}
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between text-[11px]">
          <div className={isDark ? "text-slate-300 space-x-2" : "text-slate-600 space-x-2"}>
            <span>カテゴリ: {TYPE_LABEL[item.type]}</span>
            {firstGenreLabel && <span>｜ ジャンル: {firstGenreLabel}</span>}
          </div>
        </div>
        <div className="mt-3">
          <Button
            onClick={() => onViewDetail(item)}
            className={
              "w-full rounded-full text-sm font-semibold " +
              (isDark
                ? "bg-rose-400/90 hover:bg-rose-400 text-slate-950"
                : "bg-rose-400 hover:bg-rose-500 text-white")
            }
          >
            このデータの詳細を見る
          </Button>
        </div>
        <div className={"mt-2 text-[11px] " + (isDark ? "text-slate-400" : "text-slate-500")}>
          {item.createdAgo}
        </div>
      </CardContent>
    </Card>
  );
}

const PLANS = [
  {
    id: "light",
    name: "ライトプラン",
    price: "¥480 / 月",
    description: "まずは気軽に試したい方向けのエントリープラン。",
    features: ["ショッピングデータの一部が閲覧可能", "お気に入り保存 50件まで"],
  },
  {
    id: "standard",
    name: "スタンダードプラン",
    price: "¥980 / 月",
    description: "一番おすすめの標準プラン。",
    features: [
      "ショッピング・音楽データをフル閲覧",
      "お気に入り保存 無制限",
      "新着データの優先通知",
    ],
  },
  {
    id: "premium",
    name: "プレミアムプラン",
    price: "¥1,980 / 月",
    description: "コアファン向けのプレミアムプラン。",
    features: [
      "過去アーカイブへのフルアクセス",
      "特別タグ付きデータの閲覧",
      "不定期の限定コンテンツ",
    ],
  },
];

export default function StarDataPage() {
  const [query, setQuery] = useState("");
  const [type, setType] = useState<"all" | ItemType>("all");
  const [genre, setGenre] = useState<GenreKey>("all");
  const [mode, setMode] = useState<ColorMode>("light");
  const [selectedItem, setSelectedItem] = useState<DataItem | null>(null);

  const isDark = mode === "dark";

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return ITEMS.filter((item) => {
      if (type !== "all" && item.type !== type) return false;

      if (genre !== "all") {
        if (!item.genres || !item.genres.includes(genre)) return false;
      }

      if (!q) return true;
      const haystack = `${item.title} ${item.description} ${item.service}`.toLowerCase();
      return haystack.includes(q);
    });
  }, [query, type, genre]);

  const handleViewDetail = (item: DataItem) => {
    if (item.type === "youtube") {
      setSelectedItem(null);
      return;
    }
    setSelectedItem(item);
  };

  const currentGenreOptions: GenreKey[] = type === "all" ? [] : GENRES_BY_TYPE[type];

  return (
    <div className={isDark ? "min-h-screen bg-slate-950 text-slate-50" : "min-h-screen bg-slate-50 text-slate-900"}>
      <div className="mx-auto max-w-5xl px-4 py-6 space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-cyan-300 via-violet-400 to-pink-400" />
            <div>
              <div className="text-base font-semibold">{STAR.name}</div>
              <div className={"text-xs " + (isDark ? "text-slate-400" : "text-slate-500")}>
                @{STAR.handle} のデータページ（プレビュー）
              </div>
            </div>
          </div>
        </div>
        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => setMode(isDark ? "light" : "dark")}
            className={
              isDark
                ? "inline-flex items-center rounded-full border border-slate-600 px-3 py-1 text-xs text-slate-200 hover:bg-slate-800"
                : "inline-flex items-center rounded-full border border-slate-300 px-3 py-1 text-xs text-slate-700 hover:bg-slate-100"
            }
          >
            {isDark ? "ライトモードに切り替え" : "ダークモードに切り替え"}
          </button>
        </div>
        <Separator className={isDark ? "bg-slate-800" : "bg-slate-200"} />
        <div className="space-y-3">
          <div className="relative max-w-md">
            <Search
              className={
                "pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 " +
                (isDark ? "text-slate-500" : "text-slate-400")
              }
            />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="キーワードで検索（タイトル・内容・サービス名など）"
              className={
                "pl-9 text-sm " +
                (isDark
                  ? "bg-slate-900 border-slate-700 text-slate-50 placeholder:text-slate-500"
                  : "bg-white border-slate-300 text-slate-900 placeholder:text-slate-400")
              }
            />
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {(["all", "youtube", "shopping", "music", "receipt"] as const).map((t) => (
              <TypeFilterChip
                key={t}
                value={t}
                active={type === t}
                onClick={() => {
                  setType(t);
                  setGenre("all");
                }}
              />
            ))}
          </div>
          {type !== "all" && currentGenreOptions.length > 0 && (
            <div className="flex flex-wrap items-center gap-2">
              <GenreFilterChip value="all" active={genre === "all"} onClick={() => setGenre("all")} />
              {currentGenreOptions.map((g) => (
                <GenreFilterChip key={g} value={g} active={genre === g} onClick={() => setGenre(g)} />
              ))}
            </div>
          )}
        </div>
        <div className="pt-2 pb-10 space-y-6">
          {filtered.length === 0 && (
            <Card
              className={
                isDark
                  ? "bg-slate-900 border border-dashed border-slate-700"
                  : "bg-white border border-dashed border-slate-300"
              }
            >
              <CardContent className="py-8 text-center text-sm">
                <span className={isDark ? "text-slate-400" : "text-slate-500"}>
                  条件に合うデータがありません。検索キーワードやカテゴリ・ジャンルを少し緩めてみてください。
                </span>
              </CardContent>
            </Card>
          )}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {filtered.map((item) => (
              <PackCard key={item.id} item={item} mode={mode} onViewDetail={handleViewDetail} />
            ))}
          </div>
        </div>
      </div>
      {selectedItem && selectedItem.type !== "youtube" && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div
            className={
              (isDark ? "bg-slate-900 border border-amber-500/40" : "bg-white border border-amber-300") +
              " max-w-3xl w-full rounded-3xl shadow-xl"
            }
          >
            <div className="py-6 px-4 sm:px-6 space-y-4">
              <div className="text-center space-y-1">
                <div className="text-xs font-semibold text-amber-500 tracking-[0.16em] uppercase">
                  この先は有料プラン限定
                </div>
                <div className="text-sm sm:text-base font-semibold">
                  「{selectedItem.title}」の詳細データは有料プランでご覧いただけます。
                </div>
                <div className={"text-[11px] " + (isDark ? "text-slate-400" : "text-slate-500")}>
                  YouTube視聴データは無料で閲覧できます。ショッピング・音楽・レシートなどの詳細は有料プラン対象です。
                </div>
              </div>
              <div className="grid gap-3 md:grid-cols-3">
                {PLANS.map((plan) => (
                  <div
                    key={plan.id}
                    className={
                      isDark
                        ? "rounded-2xl border border-slate-700 bg-slate-900/80 p-4 flex flex-col"
                        : "rounded-2xl border border-slate-200 bg-slate-50 p-4 flex flex-col"
                    }
                  >
                    <div className="text-sm font-semibold mb-1">{plan.name}</div>
                    <div className="text-base font-bold mb-2">{plan.price}</div>
                    <div className={"text-xs mb-2 " + (isDark ? "text-slate-300" : "text-slate-600")}>
                      {plan.description}
                    </div>
                    <ul className="space-y-1 text-[11px] flex-1">
                      {plan.features.map((f) => (
                        <li key={f} className="flex gap-1">
                          <span>・</span>
                          <span>{f}</span>
                        </li>
                      ))}
                    </ul>
                    <Button
                      className={
                        "mt-3 w-full rounded-full text-xs font-semibold " +
                        (plan.id === "standard"
                          ? isDark
                            ? "bg-amber-400/90 hover:bg-amber-400 text-slate-950"
                            : "bg-amber-400 hover:bg-amber-500 text-slate-900"
                          : isDark
                          ? "bg-slate-800 hover:bg-slate-700 text-slate-100"
                          : "bg-white hover:bg-slate-100 text-slate-800 border border-slate-200")
                      }
                    >
                      このプランを選ぶ
                    </Button>
                  </div>
                ))}
              </div>
              <div className="flex justify-center">
                <button
                  type="button"
                  onClick={() => setSelectedItem(null)}
                  className={
                    "text-[11px] underline-offset-2 hover:underline " +
                    (isDark ? "text-slate-400" : "text-slate-500")
                  }
                >
                  閉じる
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}







