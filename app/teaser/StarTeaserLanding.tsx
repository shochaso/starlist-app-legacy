"use client";

import Image from 'next/image';
import { useEffect, useMemo, useRef, useState } from 'react';

// ---- Profit Simulator v2 ----

type PlatformKey = 'YouTube' | 'X（Twitter）' | 'Instagram' | 'TikTok';
type GenreKey =
  | 'vtuber_stream'
  | 'vtuber_video'
  | 'game_stream'
  | 'game_video'
  | 'chat_stream'
  | 'entertainment'
  | 'beauty'
  | 'fashion'
  | 'gadget'
  | 'gourmet'
  | 'fitness'
  | 'business'
  | 'travel'
  | 'lifestyle'
  | 'music'
  | 'asmr';
type LegacyGenreKey = 'VTuber' | '配信者' | 'クリエイター' | 'アイドル' | '学生' | 'その他';

type FocusKey = 'focus_membership' | 'focus_tips' | 'focus_affiliate' | 'focus_balance';
type ProfitEstimateInput = {
  followers: number;
  platform: PlatformKey;
  genre: GenreKey;
};

type ProfitEstimateResult = {
  estimatedMonthlyProfit: number; // 合計推定月収（円）
  estimatedPaidMembers: number; // 推定有料会員数（人）
  paidPenetrationRate: number; // 有料加入率（%）
  arpu: number; // 有料1人あたり月間利益（合計, 円）
  arpuMembership: number; // メンバーシップのみの1人あたり利益（円）
  membershipRevenue: number; // メンバーシップ収益（円）
  tipsRevenue: number; // チップ/投げ銭の収益（円）
  affiliateRevenue: number; // 応援購入/アフィリエイト収益（円）
};

const SIM_CONFIG = {
  baseEngagementRate: 0.4,
  baseConversionRate: 0.02,
  netShare: 0.88,
  planPricing: {
    entry: 400,
    standard: 700,
    premium: 1200,
  },
  planMix: {
    entry: 0.4,
    standard: 0.45,
    premium: 0.15,
  },
  baseTipPerPaid: 120,
  baseAffiliatePerPaid: 80,
} as const;

type PlatformProfile = {
  engagement: number;
  conversion: number;
  monetization: number;
  upsellPotential: number;
  affiliatePotential: number;
};

const PLATFORM_PROFILES: Record<PlatformKey, PlatformProfile> = {
  YouTube: {
    engagement: 1.1,
    conversion: 1.1,
    monetization: 1.1,
    upsellPotential: 1.1,
    affiliatePotential: 1.05,
  },
  'X（Twitter）': {
    engagement: 1.02,
    conversion: 0.95,
    monetization: 0.95,
    upsellPotential: 0.98,
    affiliatePotential: 0.9,
  },
  Instagram: {
    engagement: 1.0,
    conversion: 1.0,
    monetization: 1.0,
    upsellPotential: 1.0,
    affiliatePotential: 1.0,
  },
  TikTok: {
    engagement: 0.97,
    conversion: 0.9,
    monetization: 0.9,
    upsellPotential: 1.05,
    affiliatePotential: 0.95,
  },
};

type GenreProfile = {
  loyalty: number;
  conversionBoost: number;
  monetizationBoost: number;
  upsellAffinity: number;
  affiliateAffinity: number;
};

const GENRE_PROFILES: Record<LegacyGenreKey, GenreProfile> = {
  VTuber: {
    loyalty: 1.12,
    conversionBoost: 1.1,
    monetizationBoost: 1.05,
    upsellAffinity: 1.1,
    affiliateAffinity: 1.1,
  },
  配信者: {
    loyalty: 1.08,
    conversionBoost: 1.05,
    monetizationBoost: 1.02,
    upsellAffinity: 1.05,
    affiliateAffinity: 1.05,
  },
  クリエイター: {
    loyalty: 1.0,
    conversionBoost: 1.0,
    monetizationBoost: 1.0,
    upsellAffinity: 1.0,
    affiliateAffinity: 1.0,
  },
  アイドル: {
    loyalty: 1.1,
    conversionBoost: 1.1,
    monetizationBoost: 1.08,
    upsellAffinity: 1.12,
    affiliateAffinity: 1.12,
  },
  学生: {
    loyalty: 0.9,
    conversionBoost: 0.85,
    monetizationBoost: 0.85,
    upsellAffinity: 0.85,
    affiliateAffinity: 0.85,
  },
  その他: {
    loyalty: 0.95,
    conversionBoost: 0.95,
    monetizationBoost: 0.95,
    upsellAffinity: 0.95,
    affiliateAffinity: 0.95,
  },
};

type PlatformProfileV2 = {
  activeRate: number;
  membershipConvBase: number;
  arppuBase: number;
  tipsRateBase: number;
  tipsArppuBase: number;
  affiliateIntentBase: number;
  affiliateArppuBase: number;
};

const PLATFORM_PROFILES_V2: Record<PlatformKey, PlatformProfileV2> = {
  YouTube: {
    activeRate: 0.38,
    membershipConvBase: 0.055,
    arppuBase: 1100,
    tipsRateBase: 0.25,
    tipsArppuBase: 320,
    affiliateIntentBase: 0.08,
    affiliateArppuBase: 250,
  },
  'X（Twitter）': {
    activeRate: 0.32,
    membershipConvBase: 0.045,
    arppuBase: 950,
    tipsRateBase: 0.18,
    tipsArppuBase: 220,
    affiliateIntentBase: 0.06,
    affiliateArppuBase: 200,
  },
  Instagram: {
    activeRate: 0.35,
    membershipConvBase: 0.05,
    arppuBase: 1050,
    tipsRateBase: 0.21,
    tipsArppuBase: 280,
    affiliateIntentBase: 0.07,
    affiliateArppuBase: 220,
  },
  TikTok: {
    activeRate: 0.29,
    membershipConvBase: 0.04,
    arppuBase: 900,
    tipsRateBase: 0.2,
    tipsArppuBase: 260,
    affiliateIntentBase: 0.065,
    affiliateArppuBase: 210,
  },
};

type GenreProfileV2 = {
  activeMult: number;
  membershipMult: number;
  tipsAffinity: number;
  purchaseIntent: number;
};

const GENRE_PROFILES_V2: Record<GenreKey, GenreProfileV2> = {
  vtuber_stream: { activeMult: 1.15, membershipMult: 1.1, tipsAffinity: 1.2, purchaseIntent: 1.1 },
  vtuber_video: { activeMult: 1.08, membershipMult: 1.05, tipsAffinity: 1.15, purchaseIntent: 1.05 },
  game_stream: { activeMult: 1.05, membershipMult: 1.0, tipsAffinity: 1.0, purchaseIntent: 0.95 },
  game_video: { activeMult: 1.02, membershipMult: 0.98, tipsAffinity: 0.95, purchaseIntent: 0.9 },
  chat_stream: { activeMult: 0.95, membershipMult: 0.9, tipsAffinity: 0.85, purchaseIntent: 0.9 },
  entertainment: { activeMult: 0.98, membershipMult: 0.97, tipsAffinity: 0.92, purchaseIntent: 0.93 },
  beauty: { activeMult: 1.1, membershipMult: 1.08, tipsAffinity: 1.05, purchaseIntent: 1.02 },
  fashion: { activeMult: 1.07, membershipMult: 1.03, tipsAffinity: 0.98, purchaseIntent: 1.0 },
  gadget: { activeMult: 1.04, membershipMult: 1.02, tipsAffinity: 0.9, purchaseIntent: 1.05 },
  gourmet: { activeMult: 0.96, membershipMult: 0.95, tipsAffinity: 0.9, purchaseIntent: 1.1 },
  fitness: { activeMult: 1.0, membershipMult: 1.0, tipsAffinity: 1.0, purchaseIntent: 0.9 },
  business: { activeMult: 0.9, membershipMult: 0.92, tipsAffinity: 0.85, purchaseIntent: 1.2 },
  travel: { activeMult: 0.92, membershipMult: 0.95, tipsAffinity: 0.9, purchaseIntent: 1.15 },
  lifestyle: { activeMult: 1.03, membershipMult: 1.01, tipsAffinity: 0.98, purchaseIntent: 1.05 },
  music: { activeMult: 1.08, membershipMult: 1.05, tipsAffinity: 1.1, purchaseIntent: 1.0 },
  asmr: { activeMult: 0.97, membershipMult: 0.93, tipsAffinity: 0.96, purchaseIntent: 0.88 },
};

type FocusProfile = {
  membershipWeight: number;
  tipsWeight: number;
  affiliateWeight: number;
};

const FOCUS_PROFILES: Record<FocusKey, FocusProfile> = {
  focus_membership: { membershipWeight: 0.7, tipsWeight: 0.15, affiliateWeight: 0.15 },
  focus_tips: { membershipWeight: 0.3, tipsWeight: 0.55, affiliateWeight: 0.15 },
  focus_affiliate: { membershipWeight: 0.25, tipsWeight: 0.2, affiliateWeight: 0.55 },
  focus_balance: { membershipWeight: 0.45, tipsWeight: 0.35, affiliateWeight: 0.2 },
};

const GENRE_OPTIONS: { value: GenreKey; label: string }[] = [
  { value: 'chat_stream', label: '雑談' },
  { value: 'game_stream', label: 'ゲーム実況' },
  { value: 'asmr', label: 'ASMR' },
  { value: 'lifestyle', label: 'その他' },
];

const PLATFORM_FEE_RATE = 0.2;

const isDevLogging = process.env.NODE_ENV !== 'production';

const FOCUS_OPTIONS: { key: FocusKey; label: string; desc: string }[] = [
  { key: 'focus_membership', label: '会員重視', desc: '有料会員の伸びを優先' },
  { key: 'focus_tips', label: '投げ銭重視', desc: '投げ銭のアクティブ率重視' },
  { key: 'focus_affiliate', label: 'アフィ重視', desc: '応援購入・アフィリエイト収益' },
  { key: 'focus_balance', label: 'バランス', desc: '会員・投げ銭・アフィを配分' },
];

const GENRE_KEY_TO_LEGACY: Record<GenreKey, LegacyGenreKey> = {
  vtuber_stream: 'VTuber',
  vtuber_video: 'VTuber',
  game_stream: '配信者',
  game_video: '配信者',
  chat_stream: '配信者',
  entertainment: '配信者',
  beauty: '配信者',
  fashion: '配信者',
  gadget: '配信者',
  gourmet: '配信者',
  fitness: '配信者',
  business: 'その他',
  travel: 'その他',
  lifestyle: 'その他',
  music: 'アイドル',
  asmr: 'その他',
};

// TODO: refine mapping when more categories/genres exist

const clamp = (value: number, min: number, max: number): number =>
  Math.min(max, Math.max(min, value));

const followerScale = (followers: number): number => {
  if (followers <= 0) return 0;

  // 小規模クリエイターを少し優遇しつつ、
  // フォロワー数が増えても「フォロワー数を1人増やしたら推定月収が下がる」ことがないよう
  // なだらかにスケールを減少させる連続関数にする。

  const clamped = Math.min(followers, 100000);
  const maxBonus = 0.15; // フォロワーが少ないほど最大 +0.15 までブースト
  const decayPerFollower = maxBonus / 100000; // 10万フォロワーで 0 まで減衰

  const bonus = maxBonus - clamped * decayPerFollower; // 1.15 → 1.0 へゆるやかに収束
  const scale = 1 + Math.max(0, bonus);

  return scale;
};

export const estimateStarlistProfit = ({
  followers,
  platform,
  genre,
}: ProfitEstimateInput): ProfitEstimateResult => {
  const safeFollowers = Number.isFinite(followers) && followers > 0 ? followers : 0;

  const platformProfile = PLATFORM_PROFILES[platform];
  const legacyGenreKey = GENRE_KEY_TO_LEGACY[genre];
  const genreProfile = GENRE_PROFILES[legacyGenreKey];

  const engagementRateRaw =
    SIM_CONFIG.baseEngagementRate *
    platformProfile.engagement *
    genreProfile.loyalty *
    followerScale(safeFollowers);

  const engagementRate = clamp(engagementRateRaw, 0.1, 0.9);
  const engagedFollowers = safeFollowers * engagementRate;

  const conversionRateRaw =
    SIM_CONFIG.baseConversionRate *
    platformProfile.conversion *
    genreProfile.conversionBoost;

  const conversionRate = clamp(conversionRateRaw, 0.005, 0.1);

  const estimatedPaidMembers = engagedFollowers * conversionRate;
  const paidPenetrationRate = safeFollowers > 0 ? (estimatedPaidMembers / safeFollowers) * 100 : 0;

  const weightedPlanPrice =
    SIM_CONFIG.planPricing.entry * SIM_CONFIG.planMix.entry +
    SIM_CONFIG.planPricing.standard * SIM_CONFIG.planMix.standard +
    SIM_CONFIG.planPricing.premium * SIM_CONFIG.planMix.premium;

  const membershipArpu =
    weightedPlanPrice *
    SIM_CONFIG.netShare *
    platformProfile.monetization *
    genreProfile.monetizationBoost;

  const membershipRevenue = estimatedPaidMembers * membershipArpu;

  const tipPerPaid =
    SIM_CONFIG.baseTipPerPaid *
    platformProfile.upsellPotential *
    genreProfile.upsellAffinity;

  const affiliatePerPaid =
    SIM_CONFIG.baseAffiliatePerPaid *
    platformProfile.affiliatePotential *
    genreProfile.affiliateAffinity;

  const tipsRevenue = estimatedPaidMembers * tipPerPaid;
  const affiliateRevenue = estimatedPaidMembers * affiliatePerPaid;

  const totalRevenue = membershipRevenue + tipsRevenue + affiliateRevenue;
  const safePaid = estimatedPaidMembers || 1;
  const arpuTotal = totalRevenue / safePaid;

  return {
    estimatedMonthlyProfit: Math.round(totalRevenue),
    estimatedPaidMembers: Math.round(estimatedPaidMembers),
    paidPenetrationRate: +paidPenetrationRate.toFixed(2),
    arpu: Math.round(arpuTotal),
    arpuMembership: Math.round(membershipArpu),
    membershipRevenue: Math.round(membershipRevenue),
    tipsRevenue: Math.round(tipsRevenue),
    affiliateRevenue: Math.round(affiliateRevenue),
  };
};

type ProfitEstimateV2Params = {
  followers: number;
  platform: PlatformKey;
  genre: GenreKey;
  focus: FocusKey;
};

type ProfitEstimateV2Result = {
  membershipRevenue: number;
  tipsRevenue: number;
  affiliateRevenue: number;
  totalRevenue: number;
  platformFee: number;
  netRevenue: number;
  estimatedPaidMembers: number;
  arppu: number;
  penetration: number;
};

const estimateStarlistProfitV2 = ({
  followers,
  platform,
  genre,
  focus,
}: ProfitEstimateV2Params): ProfitEstimateV2Result => {
  const safeFollowers = Math.max(0, followers);
  const platformProfile = PLATFORM_PROFILES_V2[platform];
  const genreProfile = GENRE_PROFILES_V2[genre];
  const focusProfile = FOCUS_PROFILES[focus];

  const activeFans = safeFollowers * platformProfile.activeRate * genreProfile.activeMult;
  const paidMembers =
    activeFans *
    platformProfile.membershipConvBase *
    genreProfile.membershipMult *
    focusProfile.membershipWeight;

  const membershipRevenue = paidMembers * platformProfile.arppuBase;
  const tipsRevenue =
    activeFans *
    platformProfile.tipsRateBase *
    genreProfile.tipsAffinity *
    focusProfile.tipsWeight *
    platformProfile.tipsArppuBase;
  const affiliateRevenue =
    activeFans *
    platformProfile.affiliateIntentBase *
    genreProfile.purchaseIntent *
    focusProfile.affiliateWeight *
    platformProfile.affiliateArppuBase;

  const totalRevenue = membershipRevenue + tipsRevenue + affiliateRevenue;
  const platformFee = totalRevenue * PLATFORM_FEE_RATE;
  const netRevenue = totalRevenue - platformFee;
  const arppu = totalRevenue / Math.max(paidMembers, 1);
  const penetration = safeFollowers > 0 ? paidMembers / safeFollowers : 0;

  return {
    membershipRevenue: Math.round(membershipRevenue),
    tipsRevenue: Math.round(tipsRevenue),
    affiliateRevenue: Math.round(affiliateRevenue),
    totalRevenue: Math.round(totalRevenue),
    platformFee: Math.round(platformFee),
    netRevenue: Math.round(netRevenue),
    estimatedPaidMembers: Math.round(paidMembers),
    arppu: Math.round(arppu),
    penetration,
  };
};

const operatorName = process.env.NEXT_PUBLIC_OPERATOR_NAME;
const operatorAddress = process.env.NEXT_PUBLIC_OPERATOR_ADDRESS;
const operatorEmail = process.env.NEXT_PUBLIC_OPERATOR_EMAIL;

export default function StarTeaserLanding() {
  const [followers, setFollowers] = useState(800);
  const [platform, setPlatform] = useState<PlatformKey>('YouTube');
  const [genre, setGenre] = useState<GenreKey>('chat_stream');
  const [focus, setFocus] = useState<FocusKey>('focus_balance');
  const [showDetails, setShowDetails] = useState(false);
  const resultRef = useRef<HTMLDivElement | null>(null);
  const [email, setEmail] = useState('');
  const [snsLink, setSnsLink] = useState('');
  const [formMessage, setFormMessage] = useState('');
  const [formStatus, setFormStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [footerSection, setFooterSection] = useState<'FAQ' | 'OPERATOR' | 'PRIVACY' | null>(null);

  const hoverCard =
    'transition-transform duration-300 hover:-translate-y-1 hover:shadow-[0_20px_40px_rgba(255,179,0,0.12)] hover:border-[#FFB300]';

  const handleFollowersChange = (value: string) => {
    const parsed = Number(value);
    setFollowers(Number.isFinite(parsed) && parsed > 0 ? parsed : 0);
  };

  const profitResult = useMemo(() => {
    return estimateStarlistProfit({ followers, platform, genre });
  }, [followers, platform, genre]);

  const v2 = useMemo(
    () => estimateStarlistProfitV2({ followers, platform, genre, focus }),
    [followers, platform, genre, focus]
  );

  useEffect(() => {
    if (!isDevLogging) return;
    console.log("[teaser][focus]", focus);
  }, [focus]);

  useEffect(() => {
    if (!isDevLogging) return;
    console.log("[teaser][v2]", {
      followers,
      platform,
      genre,
      focus,
      membershipRevenue: v2.membershipRevenue,
      tipsRevenue: v2.tipsRevenue,
      affiliateRevenue: v2.affiliateRevenue,
      totalRevenue: v2.totalRevenue,
      netRevenue: v2.netRevenue,
    });
  }, [v2, followers, platform, genre, focus]);

  useEffect(() => {
    if (!resultRef.current) return;
    if (typeof window === 'undefined') return;
    const rect = resultRef.current.getBoundingClientRect();
    const isVisible = rect.top >= 0 && rect.bottom <= window.innerHeight;
    if (!isVisible) {
      resultRef.current.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, [followers, platform, genre, focus]);

  return (
    <div className="relative min-h-screen bg-black text-white">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_#020617_0,_#050816_45%,_#000000_100%)]" />
      <div className="relative">
        {/* ================= Header ================= */}
        <header className="w-full backdrop-blur bg-black border-b border-white/5">
          <div className="max-w-7xl mx-auto px-4 md:px-6 py-4 flex items-center justify-between">
            <div className="flex items-center">
              <Image
                src="/brand/starlist-logo-wordmark-white.png"
                alt="STARLIST"
                width={220}
                height={55}
                priority
              />
            </div>
            <nav className="hidden md:flex items-center gap-6 text-sm text-white/70">
              <div className="flex items-center gap-3 text-xs">
                <a
                  href="#signup"
                  className="bg-gradient-to-r from-[#FF3B9D] to-[#FF7A3C] px-4 py-2 rounded-full text-white font-semibold shadow-lg hover:brightness-110 whitespace-nowrap"
                >
                  先行登録する
                </a>
                <a
                  href="#features"
                  className="border border-[#FFB300] text-white/90 px-4 py-2 rounded-full font-semibold bg-[#050816] hover:bg-[#050816]/80 whitespace-nowrap"
                >
                  サービス
                </a>
                <a
                  href="#footer-contact"
                  className="border border-white/50 text-white/80 px-4 py-2 rounded-full hover:bg-white/5 whitespace-nowrap"
                >
                  お問い合せ
                </a>
              </div>
            </nav>
          </div>
        </header>

        {/* ================= Hero ================= */}
        <section className="relative overflow-hidden py-16">
          <div className="relative max-w-5xl mx-auto px-6 text-center">
            <h2 className="text-4xl md:text-5xl font-extrabold leading-snug text-white">
              あなたの<span className="text-[#FFB300]">“見た・聴いた・買った”記録</span>
              <br className="hidden md:block" />
              が、ファンの求めるコンテンツになる。
            </h2>
            <p className="mt-6 text-lg text-white/90 max-w-3xl mx-auto">
              視聴履歴・レシート・プレイリストを <strong>少ないステップ</strong> でかんたん投稿。
            </p>
            <div className="mt-10 flex flex-wrap justify-center">
              <a
                href="#signup"
                className="bg-gradient-to-r from-[#FF3B9D] to-[#FF7A3C] px-8 py-3 rounded-full text-white font-semibold shadow-lg hover:brightness-110"
              >
                先行登録する
              </a>
            </div>
          </div>
        </section>

        {/* ================= Profit Simulation ================= */}
        <section id="simulator" className="py-16 border-t border-white/10 bg-[#050816]">
          <div className="max-w-3xl mx-auto px-6">
            <h2 className="text-2xl font-bold text-white mb-6 text-center">利益シミュレーション</h2>
            <p className="text-sm text-white/70 mb-8 text-center">
              あなたのフォロワー数から収益のイメージをかんたん試算できます。
            </p>
            <div className="rounded-2xl bg-gradient-to-br from-[#050918] via-[#050816] to-[#020617] border border-white/10 shadow-[0_18px_45px_rgba(5,9,24,0.9)] p-6 md:p-6">
              <div className="grid md:grid-cols-3 gap-6 mb-8">
                <div>
                  <label className="block text-sm mb-1 text-white/80">SNS総フォロワー数</label>
                  <input
                    type="number"
                    value={followers}
                    onChange={(e) => handleFollowersChange(e.target.value)}
                    className="w-full p-2 rounded bg-[#020617]/70 border border-white/15 text-white placeholder:text-white/30 focus:outline-none focus:ring-2 focus:ring-[#FFB300]/60 focus:border-[#FFB300]"
                    min={500}
                  />
                  <p className="mt-1 text-xs text-white/50">
                    ※ スター登録は総フォロワー500人以上が対象
                  </p>
                </div>
                <div>
                  <label className="block text-sm mb-1 text-white/80">メイン利用SNS</label>
                  <select
                    value={platform}
                    onChange={(e) => setPlatform(e.target.value as PlatformKey)}
                    className="w-full p-2 rounded bg-[#020617]/70 border border-white/15 text-white focus:outline-none focus:ring-2 focus:ring-[#FFB300]/60 focus:border-[#FFB300]"
                  >
                    <option>YouTube</option>
                    <option>X（Twitter）</option>
                    <option>Instagram</option>
                    <option>TikTok</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm mb-1 text-white/80">ジャンル</label>
                  <select
                    value={genre}
                    onChange={(e) => setGenre(e.target.value as GenreKey)}
                    className="w-full p-2 rounded bg-[#020617]/70 border border-white/15 text-white focus:outline-none focus:ring-2 focus:ring-[#FFB300]/60 focus:border-[#FFB300]"
                  >
                    {GENRE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="md:col-span-3 mt-3">
                  <button
                    type="button"
                    className="text-xs text-white/70 underline decoration-dotted underline-offset-4"
                    onClick={() => setShowDetails((prev) => !prev)}
                    aria-expanded={showDetails}
                  >
                    {showDetails ? '詳細設定を閉じる' : '詳細設定を表示'}
                  </button>
                  {showDetails && (
                    <div className="mt-3 rounded-2xl border border-white/10 bg-white/5 p-4">
                      <p className="text-sm text-white/80 mb-2">フォーカス（活動の寄せ方）</p>
                      <div className="grid grid-cols-2 gap-2 sm:flex sm:flex-wrap sm:gap-2">
                        {FOCUS_OPTIONS.map((opt) => {
                          const isActive = focus === opt.key;
                          return (
                            <button
                              key={opt.key}
                              type="button"
                              aria-label={`フォーカス: ${opt.label}`}
                              onClick={() => setFocus(opt.key)}
                              className={`rounded-xl border px-3 py-2 text-left text-xs transition focus-visible:outline-none sm:text-sm ${
                                isActive
                                  ? 'border-slate-500 bg-slate-900/80 ring-1 ring-slate-500/40 text-white'
                                  : 'border-slate-800 bg-slate-900/40 text-white/70 hover:border-slate-700 hover:bg-slate-900/60'
                              }`}
                            >
                              <span className="block text-sm font-semibold">{opt.label}</span>
                              <span className="text-[11px] text-white/50">{opt.desc}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </div>
              </div>
              <div ref={resultRef} className="text-center space-y-3">
                <p className="text-lg text-white/80">想定月収（目安）</p>
                <p className="text-4xl font-bold text-[#FFB300]">
                  ¥{profitResult.estimatedMonthlyProfit.toLocaleString('ja-JP')}
                </p>
                <p className="text-xs text-white/60">
                  ※ 会員収益を中心に算出した目安です
                </p>
                <p className="text-xs text-white/60">
                  ※ 投げ銭・広告・アフィリエイト等は含んでいません
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ================= Features ================= */}
        <section id="features" className="py-16 border-t border-white/10 bg-[#050816]">
          <div className="max-w-5xl mx-auto px-6">
            <h2 className="text-2xl font-bold text-white mb-6 text-center">こんなことができる</h2>
            <p className="text-sm text-white/70 mb-8 text-center">STARLIST の3つの特徴</p>
            <div className="grid md:grid-cols-3 gap-6">
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold mb-2 text-white">日常のデータで収益が作れる</h3>
                <p className="text-sm text-white">
                  ファンに見た動画・聴いた音楽・買った物など、日常の情報を届けることで収益になります。
                </p>
              </div>
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold mb-2 text-white">AIが自動でまとめてくれる</h3>
                <p className="text-sm text-white">
                  スクショをアップするだけ。AIが内容を読み取り、データとして整理してくれます。
                </p>
              </div>
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold mb-2 text-white">かんたん投稿</h3>
                <p className="text-sm text-white">
                  レシートやスクショをアップすると、必要な情報だけをデータ化して数タップで投稿できます。
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ================= Records ================= */}
        <section id="records" className="py-16 bg-[#050816] border-t border-white/10">
          <div className="max-w-5xl mx-auto px-6 text-center">
            <h2 className="text-2xl font-bold text-white mb-3">どんな記録を載せられる？</h2>
            <p className="text-sm text-white/70 mb-8">
              「見た・買った・聴いた・使った」をデータにして、ファンに共有することができます。
            </p>
            <div className="grid md:grid-cols-2 gap-6 text-left">
              {[
                {
                  title: '視聴ログ',
                  desc: '閲覧した YouTube やアニメ、恋愛番組を共有できます。',
                },
                {
                  title: '買い物メモ',
                  desc: 'コンビニやネット購入の記録をリストにして共有できます。',
                },
                {
                  title: 'プレイリスト',
                  desc: '最近よく聴く曲や歌手をまとめて紹介・共有できます。',
                },
                {
                  title: 'アプリ',
                  desc: 'スマホに入っているアプリを共有できます。',
                },
              ].map((v, i) => (
                <div
                  key={i}
                  className={`rounded-2xl border border-white/10 p-6 bg-gradient-to-br from-[#0B0F1A] to-[#15182A] hover:border-[#FFB300] hover:bg-[#15182A] transition ${hoverCard}`}
                >
                  <h3 className="text-xl font-semibold text-white mb-2">{v.title}</h3>
                  <p className="text-white/90 text-sm leading-relaxed">{v.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ================= Safety ================= */}
        <section id="safety" className="py-16 bg-[#050816] border-t border-white/10">
          <div className="max-w-5xl mx-auto px-6">
            <h2 className="text-2xl font-bold text-white mb-6 text-center">セーフティ &amp; コントロール</h2>
            <p className="text-sm text-white/70 mb-8 text-center">
              安心して記録を公開するための仕組みを用意しています。
            </p>
            <div className="grid md:grid-cols-3 gap-6">
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold text-white mb-2">自動モザイク</h3>
                <p className="text-sm text-white">
                  氏名・店舗住所・QRコード・注文番号などの情報はAIが自動検出し、データとして保存しません。公開前に、非表示になっているかを投稿前にご自身でご確認ができます。
                </p>
              </div>
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold text-white mb-2">公開レベル</h3>
                <p className="text-sm text-white">
                  無料公開では、YouTube の視聴履歴を公開できます。その他の記録は、有料会員だけに限定して公開することができます。
                </p>
              </div>
              <div className={`rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 ${hoverCard}`}>
                <h3 className="text-lg font-semibold text-white mb-2">あとから守れる</h3>
                <p className="text-sm text-white">
                  投稿したあとでも、モザイクの追加・非公開・削除がすぐにできます。スクショ対策の透かしや通報・ブロック機能も、今後のアップデートで順次導入予定です。
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ================= Signup ================= */}
        <section id="signup" className="py-16 bg-[#050816] border-t border-white/10">
          <div className="max-w-3xl mx-auto px-6">
            <div className="rounded-2xl bg-[#0B0F1A] border border-white/10 p-6 md:p-8">
              <p className="text-xs tracking-[0.2em] text-white/60 mb-2">先 行 登 録</p>
              <h2 className="text-2xl font-bold text-white mb-2">リリース通知を受け取る</h2>
              <p className="text-sm text-white/70 mb-6">
                サービスが始まったら、登録した方法でお知らせします。
              </p>

              <form
                className="space-y-4"
                onSubmit={(event) => {
                  event.preventDefault();
                  if (!email) {
                    setFormStatus('error');
                    setFormMessage('メールアドレスは必須です。');
                    return;
                  }
                  setFormStatus('success');
                  setFormMessage('送信しました。ご案内まで少々お待ちください。');
                }}
              >
                <div>
                  <label className="block text-xs text-white/60 mb-1">メールアドレス（必須）</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder="name@example.com"
                    className="w-full px-4 py-3 rounded-lg bg-black/40 border border-white/20 text-sm text-white placeholder:text-white/40 focus:outline-none focus:ring-2 focus:ring-[#FFB300]"
                  />
                </div>
                <div>
                  <label className="block text-xs text-white/60 mb-1">SNSリンク（任意）</label>
                  <input
                    type="url"
                    value={snsLink}
                    onChange={(event) => setSnsLink(event.target.value)}
                    placeholder="https://"
                    className="w-full px-4 py-3 rounded-lg bg-black/40 border border-white/20 text-sm text-white placeholder:text-white/40 focus:outline-none focus:ring-2 focus:ring-[#FFB300]"
                  />
                </div>
                <button
                  type="submit"
                  className="w-full py-3 rounded-full text-sm font-semibold bg-gradient-to-r from-[#FF3B9D] to-[#FF7A3C] hover:brightness-110"
                >
                  先行登録する
                </button>
                {formStatus !== 'idle' && (
                  <p
                    className={`text-sm ${
                      formStatus === 'success' ? 'text-green-300' : 'text-red-300'
                    }`}
                  >
                    {formMessage}
                  </p>
                )}
              </form>
            </div>
          </div>
        </section>

        {/* ================= Footer ================= */}
        <footer id="footer-contact" className="py-10 border-t border-white/10 bg-[#050816]">
          <div className="w-full max-w-7xl mx-auto px-4 md:px-6 flex flex-col gap-4 text-sm text-white/60">
            <div className="flex flex-col items-start text-left md:flex-row md:items-end md:justify-between gap-6 md:gap-3">
              <div className="flex flex-col items-start">
                <div className="mb-2 -ml-1">
                  <Image
                    src="/brand/starlist-logo-wordmark-white.png"
                    alt="STARLIST"
                    width={220}
                    height={55}
                    className="object-contain"
                  />
                </div>
                <p className="text-xs text-white/50">あなたの日常を、ファンの体験に。</p>
              </div>
              <div className="flex flex-wrap justify-start md:justify-end gap-x-6 gap-y-2 items-center">
                <button
                  type="button"
                  onClick={() =>
                    setFooterSection((current) => (current === 'FAQ' ? null : 'FAQ'))
                  }
                  className="underline-offset-4 hover:underline text-white/70 hover:text-white whitespace-nowrap"
                >
                  FAQ
                </button>
                <button
                  type="button"
                  onClick={() =>
                    setFooterSection((current) => (current === 'OPERATOR' ? null : 'OPERATOR'))
                  }
                  className="underline-offset-4 hover:underline text-white/70 hover:text-white whitespace-nowrap"
                >
                  運営情報
                </button>
                <button
                  type="button"
                  onClick={() =>
                    setFooterSection((current) => (current === 'PRIVACY' ? null : 'PRIVACY'))
                  }
                  className="underline-offset-4 hover:underline text-white/70 hover:text-white whitespace-nowrap"
                >
                  プライバシーポリシー
                </button>
              </div>
            </div>

            {footerSection && (
              <div className="border-t border-white/10 pt-4 text-xs text-white/70 space-y-2">
                {footerSection === 'FAQ' && (
                  <>
                    <p className="font-semibold text-white/80">FAQ（よくある質問）</p>
                    <div className="space-y-3 text-sm text-white/80">
                      <div>
                        <p className="font-semibold text-white">Q: 誰が見られますか？</p>
                        <p>あなたの投稿は、あなたが許可した範囲のファンだけが閲覧できます。</p>
                      </div>
                      <div>
                        <p className="font-semibold text-white">Q: 身バレが不安です。大丈夫？</p>
                        <p>公開範囲の設定や、必要に応じたモザイクで配慮します。</p>
                      </div>
                      <div>
                        <p className="font-semibold text-white">Q: 何を投稿するサービスですか？</p>
                        <p>
                          視聴した作品や、購入したものなどの「ログ」をまとめてファンに公開できます。
                        </p>
                      </div>
                      <div>
                        <p className="font-semibold text-white">Q: いつから使えますか？</p>
                        <p>先行登録いただいた方から順にご案内します。</p>
                      </div>
                      <div>
                        <p className="font-semibold text-white">Q: 料金はかかりますか？</p>
                        <p>
                          提供形態・料金は調整中です。先行登録の方に優先してお知らせします。
                        </p>
                      </div>
                    </div>
                  </>
                )}
                {footerSection === 'OPERATOR' && (
                  <>
                    <p className="font-semibold text-white/80">運営情報</p>
                    {operatorName && <p>運営者名：{operatorName}</p>}
                    {operatorAddress && <p>所在地：{operatorAddress}</p>}
                    {operatorEmail && <p>お問い合わせ：{operatorEmail}</p>}
                  </>
                )}
                {footerSection === 'PRIVACY' && (
                  <>
                    <p className="font-semibold text-white/80">プライバシーポリシー（概要）</p>
                    <p>
                      STARLIST は、皆さまのプライバシーを最優先に、データを安全に取り扱います。
                      アカウントの登録・サービス提供・不正利用の防止・統計的な分析のために、必要な範囲に限ってデータを取得・利用します。
                    </p>
                    <p>
                      取得したデータは、原則として個人が特定されない形式に加工したうえで、サービスの改善や提携サービスとの連携に活用します。
                      法令に基づく場合を除き、利用目的を超えて個人情報を第三者へ販売・提供することはありません。
                    </p>
                    <p>
                      正式なプライバシーポリシー（全文）は、サービス正式リリースまでに整備し、本ページおよび専用ページにて公開します。
                    </p>
                  </>
                )}
              </div>
            )}

            <p className="text-xs text-white/50 pt-4 border-t border-white/10 mt-2">
              © 2025 STARLIST. すべての商標は各社に帰属します。
            </p>
          </div>
        </footer>
      </div>
    </div>
  );
}
