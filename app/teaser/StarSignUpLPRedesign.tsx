'use client';

import { useState, useEffect, useRef, useCallback, type ComponentPropsWithoutRef } from 'react';
import { motion, AnimatePresence, type MotionProps } from 'framer-motion';
import Image from "next/image";
import { Button } from "@/components/ui/button";
import {
    CheckCircle2,
    ChevronRight,
    ShieldCheck,
    Zap,
    Globe,
    Smartphone,
    BarChart3,
    Lock,
    Instagram,
    Youtube,
    Twitter,
    Music2, // for TikTok alternative
    ArrowRight,
    Menu,
    X
} from 'lucide-react';

// --- Types & Logic ---

type Platform = 'instagram' | 'tiktok' | 'youtube' | 'x';
type Genre = 'lifestyle' | 'tech' | 'beauty' | 'entertainment';

const platformCoeffs: Record<Platform, number> = {
    instagram: 1.2,
    tiktok: 0.8,
    youtube: 2.5,
    x: 0.5,
};

const genreCoeffs: Record<Genre, number> = {
    lifestyle: 1.0,
    tech: 1.5,
    beauty: 1.3,
    entertainment: 0.9,
};

const calcProfit = (followers: number, platform: Platform, genre: Genre) => {
    // Base calculation: followers * platform_rate * genre_multiplier * engagement_factor
    // This is a simplified simulation logic
    const baseRate = 0.05; // 5% conversion/engagement assumption
    const unitPrice = 100; // Average value per conversion in JPY

    const estimatedMonthly = Math.floor(
        followers * baseRate * platformCoeffs[platform] * genreCoeffs[genre] * unitPrice
    );

    return estimatedMonthly.toLocaleString();
};

// --- Components ---

type MotionComponent<Props> = (props: Props) => any;
type MotionSectionProps = ComponentPropsWithoutRef<"section"> & MotionProps;
type MotionDivProps = ComponentPropsWithoutRef<"div"> & MotionProps;

const MotionSection = motion.section as unknown as MotionComponent<MotionSectionProps>;
const MotionDiv = motion.div as unknown as MotionComponent<MotionDivProps>;

const Section = ({ children, className = "", id = "" }: { children: React.ReactNode; className?: string; id?: string }) => (
    <MotionSection
        id={id}
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-100px" }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className={`py-20 md:py-32 px-4 sm:px-6 relative z-10 ${className}`}
    >
        {children}
    </MotionSection>
);

const GlassCard = ({ children, className = "" }: { children: React.ReactNode; className?: string }) => (
    <div className={`bg-white/5 border border-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 hover:bg-white/10 transition-colors duration-300 ${className}`}>
        {children}
    </div>
);

export default function StarSignUpLPRedesign() {
    const isDev = process.env.NODE_ENV !== "production";
    const logEvent = useCallback(
        (event: string, payload: Record<string, unknown> = {}) => {
            if (!isDev) return;
            console.log("[teaser][event]", { event, ...payload });
        },
        [isDev]
    );

    // State for Simulator
    const [followers, setFollowers] = useState(10000);
    const [platform, setPlatform] = useState<Platform>('instagram');
    const [genre, setGenre] = useState<Genre>('lifestyle');
    const [profit, setProfit] = useState('');
    const focus = 'none';

    // State for Signup
    const [email, setEmail] = useState('');
    const [notifyMethod, setNotifyMethod] = useState<'email' | 'line'>('email');
    const [isSubmitted, setIsSubmitted] = useState(false);

    // State for Mobile Menu
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    const hasLoggedSimulate = useRef(false);
    const hasLoggedResultView = useRef(false);
    const resultRef = useRef<HTMLDivElement | null>(null);

    useEffect(() => {
        logEvent('teaser_view');
    }, [logEvent]);

    useEffect(() => {
        setProfit(calcProfit(followers, platform, genre));
    }, [followers, platform, genre]);

    useEffect(() => {
        if (!isDev) return;
        if (!hasLoggedSimulate.current) {
            hasLoggedSimulate.current = true;
            return;
        }
        logEvent('teaser_simulate', { followers, genre, platform, focus });
    }, [followers, genre, platform, focus, isDev, logEvent]);

    useEffect(() => {
        if (!isDev) return;
        const target = resultRef.current;
        if (!target) return;

        const observer = new IntersectionObserver(
            (entries) => {
                if (hasLoggedResultView.current) return;
                const entry = entries[0];
                if (entry?.isIntersecting) {
                    hasLoggedResultView.current = true;
                    logEvent('teaser_result_view');
                    observer.disconnect();
                }
            },
            { threshold: 0.3 }
        );

        observer.observe(target);
        return () => observer.disconnect();
    }, [isDev, logEvent]);

    const handleScrollTo = (id: string) => {
        setIsMenuOpen(false);
        const element = document.getElementById(id);
        if (element) {
            element.scrollIntoView({ behavior: 'smooth' });
        }
    };
    const handleCtaClick = (position: 'hero' | 'footer') => {
        logEvent('teaser_cta_click', { cta_position: position });
        handleScrollTo('signup');
    };

    return (
        <div className="min-h-screen bg-black text-white selection:bg-[#227CFF] selection:text-white overflow-hidden font-sans">

            {/* --- Background Effects --- */}
            <div className="fixed inset-0 z-0 pointer-events-none">
                <div className="absolute top-[-10%] left-[-10%] w-[60vw] h-[60vw] bg-[#227CFF]/10 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[60vw] h-[60vw] bg-purple-600/10 rounded-full blur-[120px]" />
                <div className="absolute top-[40%] left-[30%] w-[40vw] h-[40vw] bg-blue-500/5 rounded-full blur-[100px]" />
            </div>

            {/* --- Header --- */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/50 backdrop-blur-md border-b border-white/10">
                <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">

                    {/* Logo */}
                    <div className="flex items-center gap-3 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
                        <Image
                            src="/starlist-logo.png"
                            alt="STARLIST Logo"
                            width={32}
                            height={32}
                            className="rounded-md w-8 h-8 object-cover"
                            priority
                        />
                        <h1 className="text-xl md:text-2xl font-extrabold tracking-tight">
                            <span className="text-white">STAR</span>
                            <span className="text-[#227CFF]">LIST</span>
                        </h1>
                    </div>

                    {/* Desktop Nav */}
                    <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-300">
                        {['特徴', '使い方', 'シミュレーション', '収益化', '安全性'].map((item, i) => {
                            const ids = ['features', 'how', 'simulator', 'plans', 'safety'];
                            return (
                                <button key={item} onClick={() => handleScrollTo(ids[i])} className="hover:text-white transition-colors">
                                    {item}
                                </button>
                            );
                        })}
                    </nav>

                    {/* CTA & Mobile Menu Toggle */}
                    <div className="flex items-center gap-4">
                        <Button
                            onClick={() => handleScrollTo('signup')}
                            className="hidden md:flex bg-[#227CFF] hover:bg-[#1b6ad6] text-white rounded-full px-6"
                        >
                            事前登録
                        </Button>
                        <button className="md:hidden text-white" onClick={() => setIsMenuOpen(!isMenuOpen)}>
                            {isMenuOpen ? <X /> : <Menu />}
                        </button>
                    </div>
                </div>

                {/* Mobile Menu */}
                <AnimatePresence>
                    {isMenuOpen && (
                        <MotionDiv
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            exit={{ opacity: 0, height: 0 }}
                            className="md:hidden bg-black border-b border-white/10 overflow-hidden"
                        >
                            <nav className="flex flex-col p-6 gap-4 text-gray-300">
                                {['特徴', '使い方', 'シミュレーション', '収益化', '安全性'].map((item, i) => {
                                    const ids = ['features', 'how', 'simulator', 'plans', 'safety'];
                                    return (
                                        <button key={item} onClick={() => handleScrollTo(ids[i])} className="text-left hover:text-white py-2">
                                            {item}
                                        </button>
                                    );
                                })}
                                <Button onClick={() => handleScrollTo('signup')} className="bg-[#227CFF] text-white w-full mt-4">
                                    事前登録する
                                </Button>
                            </nav>
                        </MotionDiv>
                    )}
                </AnimatePresence>
            </header>

            {/* --- Main Content --- */}
            <main className="pt-16">

                {/* 1. Hero Section */}
                <Section className="min-h-[80vh] flex flex-col items-center justify-center text-center">
                    <MotionDiv
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 0.8 }}
                        className="mb-6 inline-block"
                    >
                        <span className="px-4 py-1.5 rounded-full bg-white/10 border border-white/20 text-sm font-medium text-blue-300 backdrop-blur-sm">
                            ✨ 次世代のクリエイターエコノミー
                        </span>
                    </MotionDiv>

                    <h2 className="text-4xl sm:text-5xl md:text-7xl font-black tracking-tight mb-8 leading-tight">
                        あなたの<br className="md:hidden" />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400">
                            “見た・聴いた・買った”
                        </span>
                        <br />
                        記録が価値になる
                    </h2>

                    <p className="text-lg sm:text-xl md:text-2xl text-gray-400 max-w-3xl mx-auto mb-12 leading-relaxed break-words">
                        Starlistは、あなたの愛用アイテムや体験をリスト化し、<br className="hidden md:block" />
                        ファンと共有することで収益を生み出す新しいプラットフォームです。
                    </p>

                    <div className="flex flex-col md:flex-row gap-4 w-full max-w-md mx-auto">
                        <Button
                            onClick={() => handleCtaClick('hero')}
                            className="h-14 w-full md:w-auto text-base sm:text-lg rounded-full bg-[#227CFF] hover:bg-[#1b6ad6] shadow-[0_0_30px_rgba(34,124,255,0.4)] transition-all hover:scale-105"
                        >
                            無料で事前登録する <ArrowRight className="ml-2 w-5 h-5" />
                        </Button>
                    </div>
                </Section>

                {/* 2. Simulator Section */}
                <Section id="simulator" className="bg-black/20">
                    <div className="max-w-4xl mx-auto">
                        <div className="text-center mb-12">
                            <h3 className="text-3xl md:text-4xl font-bold mb-4">収益シミュレーター</h3>
                            <p className="text-gray-400">あなたの影響力がどれくらいの価値になるか、計算してみましょう。</p>
                        </div>

                        <GlassCard className="border-t-4 border-t-[#227CFF]">
                            <div className="grid md:grid-cols-2 gap-12">

                                {/* Inputs */}
                                <div className="space-y-8">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-300 mb-3">フォロワー数: {followers.toLocaleString()}</label>
                                        <input
                                            type="range"
                                            min="1000"
                                            max="1000000"
                                            step="1000"
                                            value={followers}
                                            onChange={(e) => setFollowers(Number(e.target.value))}
                                            className="w-full h-2 bg-white/10 rounded-lg appearance-none cursor-pointer accent-[#227CFF]"
                                        />
                                    </div>

                                    <div>
                                        <label className="block text-sm font-medium text-gray-300 mb-3">メインプラットフォーム</label>
                                        <div className="grid grid-cols-2 gap-3">
                                            {(['instagram', 'tiktok', 'youtube', 'x'] as Platform[]).map((p) => (
                                                <button
                                                    key={p}
                                                    onClick={() => setPlatform(p)}
                                                    className={`flex items-center justify-center gap-2 py-3 rounded-lg border transition-all ${platform === p
                                                            ? 'bg-[#227CFF]/20 border-[#227CFF] text-white'
                                                            : 'bg-white/5 border-white/10 text-gray-400 hover:bg-white/10'
                                                        }`}
                                                >
                                                    {p === 'instagram' && <Instagram className="w-4 h-4" />}
                                                    {p === 'tiktok' && <Music2 className="w-4 h-4" />}
                                                    {p === 'youtube' && <Youtube className="w-4 h-4" />}
                                                    {p === 'x' && <Twitter className="w-4 h-4" />}
                                                    <span className="capitalize">{p}</span>
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    <div>
                                        <label className="block text-sm font-medium text-gray-300 mb-3">ジャンル</label>
                                        <select
                                            value={genre}
                                            onChange={(e) => setGenre(e.target.value as Genre)}
                                            className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#227CFF]"
                                        >
                                            <option value="lifestyle">ライフスタイル</option>
                                            <option value="tech">ガジェット・テック</option>
                                            <option value="beauty">美容・コスメ</option>
                                            <option value="entertainment">エンタメ</option>
                                        </select>
                                    </div>
                                </div>

                                {/* Result */}
                                <div
                                    ref={resultRef}
                                    className="flex flex-col justify-center items-center text-center bg-gradient-to-br from-white/5 to-white/0 rounded-xl p-8 border border-white/5"
                                >
                                    <p className="text-gray-400 mb-2">月間の推定収益</p>
                                    <div className="text-4xl sm:text-5xl md:text-6xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#227CFF] to-purple-400 mb-4 tabular-nums whitespace-nowrap">
                                        ¥{profit}
                                    </div>
                                    <p className="text-sm text-gray-500 leading-relaxed break-words">
                                        ※ 独自のアルゴリズムによる試算です。<br />実際の収益を保証するものではありません。
                                    </p>
                                </div>
                            </div>
                        </GlassCard>
                    </div>
                </Section>

                {/* 3. Features Section */}
                <Section id="features">
                    <div className="text-center mb-16">
                        <h3 className="text-3xl md:text-4xl font-bold mb-4">Starlistの特徴</h3>
                        <p className="text-gray-400">クリエイターのために設計された、強力なツール群。</p>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                        {[
                            { icon: Globe, title: "All in One", desc: "SNSごとのバラバラなリンクを、ひとつの美しいページにまとめましょう。" },
                            { icon: BarChart3, title: "Analytics", desc: "どのアイテムが注目されているか、詳細なデータで分析できます。" },
                            { icon: Smartphone, title: "Mobile First", desc: "スマホでの閲覧に最適化された、直感的でスムーズなデザイン。" },
                            { icon: Zap, title: "Instant Setup", desc: "面倒な登録は不要。SNSアカウント連携で、1分でスタート。" },
                        ].map((feature, i) => (
                            <GlassCard key={i} className="text-center group">
                                <div className="w-12 h-12 mx-auto bg-white/5 rounded-full flex items-center justify-center mb-6 group-hover:bg-[#227CFF]/20 group-hover:text-[#227CFF] transition-colors">
                                    <feature.icon className="w-6 h-6" />
                                </div>
                                <h4 className="text-xl font-bold mb-3">{feature.title}</h4>
                                <p className="text-gray-400 text-sm leading-relaxed">{feature.desc}</p>
                            </GlassCard>
                        ))}
                    </div>
                </Section>

                {/* 4. How it Works */}
                <Section id="how" className="bg-gradient-to-b from-transparent to-[#051020]">
                    <div className="max-w-5xl mx-auto">
                        <div className="text-center mb-16">
                            <h3 className="text-3xl md:text-4xl font-bold mb-4">使い方はとてもシンプル</h3>
                        </div>

                        <div className="grid md:grid-cols-3 gap-8">
                            {[
                                { step: "01", title: "リストを作成", desc: "愛用品やおすすめのサービスを登録して、リストを作成します。" },
                                { step: "02", title: "SNSでシェア", desc: "発行されたURLを、InstagramやTikTokのプロフィールに貼るだけ。" },
                                { step: "03", title: "収益を受け取る", desc: "ファンがリストから購入・登録すると、あなたに報酬が入ります。" },
                            ].map((item, i) => (
                                <div key={i} className="relative">
                                    <div className="text-6xl font-black text-white/5 absolute -top-8 -left-4 z-0">{item.step}</div>
                                    <GlassCard className="relative z-10 h-full border-t border-white/20">
                                        <h4 className="text-xl font-bold mb-4">{item.title}</h4>
                                        <p className="text-gray-400">{item.desc}</p>
                                    </GlassCard>
                                </div>
                            ))}
                        </div>
                    </div>
                </Section>

                {/* 5. Records (Examples) */}
                <Section id="records">
                    <div className="flex flex-col md:flex-row items-center gap-12">
                        <div className="flex-1">
                            <h3 className="text-3xl md:text-4xl font-bold mb-6">
                                どんな記録を<br />載せられる？
                            </h3>
                            <p className="text-gray-400 mb-8 leading-relaxed break-words">
                                ガジェット、コスメ、書籍、旅行の思い出、サウナの記録...。<br />
                                Amazonや楽天の商品はもちろん、
                                あなただけの体験もコンテンツになります。
                            </p>
                            <ul className="space-y-4">
                                {['愛用しているデスク環境', '今月読んでよかった本', '週末に行ったカフェ巡り', 'リピートしているスキンケア'].map((item) => (
                                    <li key={item} className="flex items-center gap-3 text-gray-300">
                                        <CheckCircle2 className="w-5 h-5 text-[#227CFF]" />
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        </div>
                        <div className="flex-1 relative">
                            {/* Abstract Visual Representation of a List */}
                            <div className="relative w-full aspect-square max-w-md mx-auto">
                                <div className="absolute inset-0 bg-gradient-to-tr from-[#227CFF]/20 to-purple-500/20 rounded-full blur-3xl" />
                                <GlassCard className="absolute inset-4 flex flex-col gap-4 p-6 rotate-3">
                                    <div className="h-32 bg-white/10 rounded-lg animate-pulse" />
                                    <div className="h-4 w-3/4 bg-white/10 rounded animate-pulse" />
                                    <div className="h-4 w-1/2 bg-white/10 rounded animate-pulse" />
                                </GlassCard>
                                <GlassCard className="absolute inset-4 flex flex-col gap-4 p-6 -rotate-3 translate-y-4 bg-black/80">
                                    <div className="flex items-center gap-4 mb-4">
                                        <div className="w-10 h-10 rounded-full bg-gray-700" />
                                        <div>
                                            <div className="w-24 h-3 bg-gray-700 rounded mb-2" />
                                            <div className="w-16 h-3 bg-gray-800 rounded" />
                                        </div>
                                    </div>
                                    <div className="h-40 bg-white/5 rounded-lg border border-white/10 flex items-center justify-center text-gray-600">
                                        Item Image
                                    </div>
                                </GlassCard>
                            </div>
                        </div>
                    </div>
                </Section>

                {/* 6. Plans & Safety */}
                <Section id="plans" className="bg-[#050505]">
                    <div className="grid md:grid-cols-2 gap-12 max-w-6xl mx-auto">

                        {/* Plans */}
                        <div>
                            <h3 className="text-3xl font-bold mb-6">フォロワーをファンに変える</h3>
                            <p className="text-gray-400 mb-8">
                                単なるアフィリエイトではありません。<br />
                                あなたのセンスやライフスタイルそのものが価値になります。
                            </p>
                            <GlassCard className="border-[#227CFF]/30 bg-[#227CFF]/5">
                                <h4 className="text-xl font-bold text-[#227CFF] mb-2">Early Access Plan</h4>
                                <div className="text-4xl font-bold mb-4">Free<span className="text-lg text-gray-500 font-normal"> / forever</span></div>
                                <p className="text-gray-400 text-sm mb-6">
                                    ベータ期間中に登録された方は、<br />
                                    将来有料化されるプレミアム機能も永年無料でご利用いただけます。
                                </p>
                                <Button onClick={() => handleCtaClick('footer')} className="w-full bg-[#227CFF] hover:bg-[#1b6ad6]">
                                    今すぐ枠を確保する
                                </Button>
                            </GlassCard>
                        </div>

                        {/* Safety */}
                        <div id="safety">
                            <h3 className="text-3xl font-bold mb-6">安心・安全への取り組み</h3>
                            <div className="space-y-6">
                                <GlassCard className="flex gap-4">
                                    <ShieldCheck className="w-8 h-8 text-green-400 shrink-0" />
                                    <div>
                                        <h4 className="font-bold mb-1">厳格な審査基準</h4>
                                        <p className="text-sm text-gray-400">掲載される商品はすべて審査され、安全性が確認されたもののみが表示されます。</p>
                                    </div>
                                </GlassCard>
                                <GlassCard className="flex gap-4">
                                    <Lock className="w-8 h-8 text-yellow-400 shrink-0" />
                                    <div>
                                        <h4 className="font-bold mb-1">プライバシー保護</h4>
                                        <p className="text-sm text-gray-400">あなたの個人情報は最新の暗号化技術で守られています。</p>
                                    </div>
                                </GlassCard>
                            </div>
                        </div>

                    </div>
                </Section>

                {/* 7. Signup Form */}
                <Section id="signup" className="py-32">
                    <div className="max-w-xl mx-auto text-center">
                        <h3 className="text-4xl md:text-5xl font-black mb-6">
                            先行登録受付中
                        </h3>
                        <p className="text-xl text-gray-400 mb-12">
                            リリース時にいち早く通知を受け取り、<br />
                            限定特典を手に入れましょう。
                        </p>

                        <GlassCard className="p-8 md:p-10 text-left">
                            {!isSubmitted ? (
                                <form
                                    onSubmit={(e) => {
                                        e.preventDefault();
                                        logEvent('teaser_signup_submit', { has_sns: notifyMethod === 'line' });
                                        setIsSubmitted(true);
                                    }}
                                    className="space-y-6"
                                >
                                    <div>
                                        <label className="block text-sm font-medium text-gray-300 mb-2">メールアドレス</label>
                                        <input
                                            type="email"
                                            required
                                            value={email}
                                            onChange={(e) => setEmail(e.target.value)}
                                            placeholder="hello@example.com"
                                            className="w-full bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#227CFF] transition-colors"
                                        />
                                    </div>

                                    <div>
                                        <label className="block text-sm font-medium text-gray-300 mb-2">通知方法</label>
                                        <div className="flex gap-4">
                                            <label className="flex items-center gap-2 cursor-pointer">
                                                <input
                                                    type="radio"
                                                    name="notify"
                                                    checked={notifyMethod === 'email'}
                                                    onChange={() => setNotifyMethod('email')}
                                                    className="accent-[#227CFF]"
                                                />
                                                <span className="text-sm text-gray-300">メールで受け取る</span>
                                            </label>
                                            <label className="flex items-center gap-2 cursor-pointer">
                                                <input
                                                    type="radio"
                                                    name="notify"
                                                    checked={notifyMethod === 'line'}
                                                    onChange={() => setNotifyMethod('line')}
                                                    className="accent-[#227CFF]"
                                                />
                                                <span className="text-sm text-gray-300">LINEで受け取る</span>
                                            </label>
                                        </div>
                                    </div>

                                    <Button type="submit" className="w-full h-12 text-lg bg-[#227CFF] hover:bg-[#1b6ad6] rounded-lg font-bold">
                                        登録して待つ
                                    </Button>
                                    <p className="text-xs text-center text-gray-500 mt-4">
                                        登録することで、利用規約とプライバシーポリシーに同意したことになります。
                                    </p>
                                </form>
                            ) : (
                                <MotionDiv
                                    initial={{ opacity: 0, scale: 0.9 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    className="text-center py-10"
                                >
                                    <div className="w-16 h-16 bg-green-500/20 text-green-400 rounded-full flex items-center justify-center mx-auto mb-6">
                                        <CheckCircle2 className="w-8 h-8" />
                                    </div>
                                    <h4 className="text-2xl font-bold mb-2">登録ありがとうございます！</h4>
                                    <p className="text-gray-400">
                                        リリース日が決まり次第、<br />
                                        {email} 宛にお知らせいたします。
                                    </p>
                                </MotionDiv>
                            )}
                        </GlassCard>
                    </div>
                </Section>

            </main>

            {/* --- Footer --- */}
            <footer className="bg-black border-t border-white/10 py-12 px-6">
                <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-8 text-center md:text-left">
                    <div className="flex items-center gap-2">
                        <div className="w-6 h-6 bg-[#227CFF] rounded-sm" />
                        <span className="font-bold text-xl tracking-tight">STARLIST</span>
                    </div>
                    <div className="flex flex-wrap justify-center gap-4 text-sm text-gray-500">
                        <a href="#" className="hover:text-white transition-colors">運営会社</a>
                        <a href="#" className="hover:text-white transition-colors">利用規約</a>
                        <a href="#" className="hover:text-white transition-colors">プライバシーポリシー</a>
                        <a href="#" className="hover:text-white transition-colors">お問い合わせ</a>
                    </div>
                    <div className="text-xs text-gray-600">
                        © 2025 Starlist Inc. All rights reserved.
                    </div>
                </div>
            </footer>

        </div>
    );
}
