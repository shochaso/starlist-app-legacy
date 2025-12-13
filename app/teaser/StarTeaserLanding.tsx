'use client';

import Image from 'next/image';
import { useMemo, useState } from 'react';

// ---- Profit Simulator v2 ----

type PlatformKey = 'YouTube' | 'X（Twitter）' | 'Instagram' | 'TikTok';
type GenreKey = 'VTuber' | '配信者' | 'クリエイター' | 'アイドル' | '学生' | 'その他';

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

const GENRE_PROFILES: Record<GenreKey, GenreProfile> = {
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

const clamp = (value: number, min: number, max: number): number => Math.min(max, Math.max(min, value));

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
  const genreProfile = GENRE_PROFILES[genre];

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

const operatorName = process.env.NEXT_PUBLIC_OPERATOR_NAME;
const operatorAddress = process.env.NEXT_PUBLIC_OPERATOR_ADDRESS;
const operatorEmail = process.env.NEXT_PUBLIC_OPERATOR_EMAIL;

export default function StarTeaserLanding() {
  const [followers, setFollowers] = useState(500);
  const [platform, setPlatform] = useState<PlatformKey>('YouTube');
  const [genre, setGenre] = useState<GenreKey>('VTuber');
  const [notifyMethod, setNotifyMethod] = useState<'Instagram' | 'X' | 'メール' | null>(null);
  const [footerSection, setFooterSection] = useState<'FAQ' | 'OPERATOR' | 'PRIVACY' | null>(null);

  const hoverCard =
    'transition-transform duration-300 hover:-translate-y-1 hover:shadow-[0_20px_40px_rgba(255,179,0,0.12)] hover:border-[#FFB300]';

  const contactLabel =
    notifyMethod === 'メール' ? 'メールアドレス' : notifyMethod ? `${notifyMethod} ID` : '連絡先';

  const contactPlaceholder =
    notifyMethod === 'メール'
      ? '例: name@example.com'
      : notifyMethod === 'Instagram'
      ? '例: username'
      : notifyMethod === 'X'
      ? '例: @username'
      : '連絡先を入力';
  const profitResult = useMemo(() => {
    return estimateStarlistProfit({ followers, platform, genre });
  }, [followers, platform, genre]);

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
            <div className="mt-10 flex flex-wrap justify-center gap-4">
              <a
                href="#signup"
                className="bg-gradient-to-r from-[#FF3B9D] to-[#FF7A3C] px-8 py-3 rounded-full text-white font-semibold shadow-lg hover:brightness-110"
              >
                先行登録する
              </a>
              <a
                href="#how"
                className="border border-[#FFB300] text-[#FFB300] px-8 py-3 rounded-full font-semibold hover:bg-[#FFB300]/10"
              >
                仕組みを見る
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
                    onChange={(e) => setFollowers(Number(e.target.value))}
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
                    <option>VTuber</option>
                    <option>配信者</option>
                    <option>クリエイター</option>
                    <option>アイドル</option>
                    <option>学生</option>
                    <option>その他</option>
                  </select>
                </div>
              </div>
              <div className="text-center">
                <p className="text-lg text-white/80 mb-2">推定月収</p>
                <p className="text-4xl font-bold text-[#FFB300]">¥{profitResult.estimatedMonthlyProfit.toLocaleString()}</p>
                <p className="text-xs text-white/60 mt-2">※ 表示される金額はあくまで目安です。</p>
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

              <div className="flex flex-wrap gap-2 mb-4 text-sm">
                {['Instagram', 'X', 'メール'].map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => setNotifyMethod(m as any)}
                    className={
                      'px-4 py-2 rounded-full border text-xs md:text-sm ' +
                      (notifyMethod === m
                        ? 'bg-white text-black border-white'
                        : 'border-white/30 text-white/70 hover:bg-white/10')
                    }
                  >
                    {m}
                  </button>
                ))}
              </div>

              <form className="space-y-4">
                <div>
                  <label className="block text-xs text-white/60 mb-1">{contactLabel}</label>
                  <input
                    type={notifyMethod === 'メール' ? 'email' : 'text'}
                    placeholder={contactPlaceholder}
                    className="w-full px-4 py-3 rounded-lg bg-black/40 border border-white/20 text-sm text-white placeholder:text-white/40 focus:outline-none focus:ring-2 focus:ring-[#FFB300]"
                  />
                </div>
                <button
                  type="submit"
                  className="w-full py-3 rounded-full text-sm font-semibold bg-gradient-to-r from-[#FF3B9D] to-[#FF7A3C] hover:brightness-110"
                >
                  登録する
                </button>
              </form>
            </div>
          </div>
        </section>

        {/* ================= Footer ================= */}
        <footer id="footer-contact" className="py-10 border-t border-white/10 bg-[#050816]">
          <div className="w-full max-w-7xl mx-auto px-4 md:px-6 flex flex-col gap-4 text-sm text-white/60">
            <div className="flex flex-col items-start text-left md:flex-row md:items-start md:justify-between gap-6 md:gap-3">
              <div className="flex flex-col items-start">
                <div className="relative w-64 md:w-80 aspect-[2370/220] mb-2">
                  <Image
                    src="/brand/starlist-logo-clear.png"
                    alt="STARLIST ロゴ"
                    fill
                    sizes="(max-width: 768px) 256px, 320px"
                    className="object-contain object-left"
                  />
                </div>
                <p className="text-xs text-white/50">あなたの日常を、ファンの体験に。</p>
              </div>
              <div className="flex flex-wrap justify-start md:justify-end gap-x-6 gap-y-2 items-center md:pt-2">
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
                    <p>
                      現在クローズド準備中のため、FAQ は順次追加予定です。STARLIST の提供内容や
                      利用開始時期については、決まりしだいこちらに掲載します。
                    </p>
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
                      STARLIST は、サービス提供・不正利用防止・統計的な分析のために、必要な範囲でデータを
                      取得・利用します。個人が特定されない形に統計化したデータを、サービス改善や提携先との
                      連携に活用する場合があります。
                    </p>
                    <p>
                      正式なプライバシーポリシーは、サービス公開前までに整備し、本ページおよび専用ページで
                      公開します。
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
