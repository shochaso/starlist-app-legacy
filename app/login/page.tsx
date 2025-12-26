'use client';

import { useState, type ComponentPropsWithoutRef } from 'react';
import { useForm, type Resolver } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { motion, AnimatePresence, type MotionProps } from 'framer-motion';
import { Loader2, Github, Mail, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

// Validation Schemas
const loginSchema = z.object({
    email: z.string().email({ message: "有効なメールアドレスを入力してください" }),
    password: z.string().min(8, { message: "パスワードは8文字以上で入力してください" }),
});

const signUpSchema = loginSchema.extend({
    name: z.string().min(2, { message: "お名前は2文字以上で入力してください" }),
});

type LoginFormValues = z.infer<typeof loginSchema>;
type SignUpFormValues = z.infer<typeof signUpSchema>;

type MotionComponent<Props> = (props: Props) => any;
type MotionDivProps = ComponentPropsWithoutRef<"div"> & MotionProps;
type MotionButtonProps = ComponentPropsWithoutRef<"button"> & MotionProps;

const MotionDiv = motion.div as unknown as MotionComponent<MotionDivProps>;
const MotionButton = motion.button as unknown as MotionComponent<MotionButtonProps>;

export default function LoginPage() {
    const [isLogin, setIsLogin] = useState(true);
    const [isLoading, setIsLoading] = useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
        reset,
        clearErrors,
    } = useForm<SignUpFormValues>({
        resolver: zodResolver(isLogin ? loginSchema : signUpSchema) as unknown as Resolver<SignUpFormValues>,
    });

    const toggleMode = () => {
        setIsLogin(!isLogin);
        reset();
        clearErrors();
    };

    const onSubmit = async (data: SignUpFormValues) => {
        setIsLoading(true);
        // Simulate API call
        await new Promise((resolve) => setTimeout(resolve, 2000));
        console.log("Form Data:", data);
        console.log("Mode:", isLogin ? "Login" : "Sign Up");
        setIsLoading(false);
        alert(`${isLogin ? "ログイン" : "登録"}処理が完了しました（デモ）`);
    };

    return (
        <div className="min-h-screen w-full flex items-center justify-center bg-gradient-to-br from-black via-[#0a0a0a] to-[#051020] text-white p-4 font-sans selection:bg-[#227CFF] selection:text-white relative overflow-hidden">

            {/* Background Ambient Effects */}
            <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-[#227CFF]/20 rounded-full blur-[120px] pointer-events-none" />
            <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] bg-purple-600/20 rounded-full blur-[120px] pointer-events-none" />

            <MotionDiv
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5 }}
                className="w-full max-w-md"
            >
                {/* Back Link */}
                <Link href="/" className="inline-flex items-center text-sm text-gray-400 hover:text-white mb-6 transition-colors group">
                    <ArrowLeft className="w-4 h-4 mr-2 group-hover:-translate-x-1 transition-transform" />
                    トップページに戻る
                </Link>

                {/* Main Card */}
                <div className="backdrop-blur-xl bg-black/40 border border-white/10 rounded-2xl shadow-2xl overflow-hidden">
                    <div className="p-8">

                        {/* Header */}
                        <div className="text-center mb-8">
                            <h1 className="text-3xl font-bold tracking-tight mb-2">
                                <span className="text-white">STAR</span>
                                <span className="text-[#227CFF]">LIST</span>
                            </h1>
                            <p className="text-gray-400 text-sm">
                                {isLogin ? "おかえりなさい。アカウントにログインしてください。" : "新しいアカウントを作成して、始めましょう。"}
                            </p>
                        </div>

                        {/* Toggle */}
                        <div className="flex bg-white/5 rounded-lg p-1 mb-8 relative">
                            <MotionDiv
                                className="absolute top-1 bottom-1 bg-[#227CFF] rounded-md shadow-lg"
                                initial={false}
                                animate={{
                                    x: isLogin ? 0 : "100%",
                                    width: "50%"
                                }}
                                transition={{ type: "spring", stiffness: 300, damping: 30 }}
                            />
                            <button
                                onClick={() => !isLogin && toggleMode()}
                                className={`flex-1 relative z-10 text-sm font-medium py-2 transition-colors ${isLogin ? 'text-white' : 'text-gray-400 hover:text-white'}`}
                            >
                                Sign In
                            </button>
                            <button
                                onClick={() => isLogin && toggleMode()}
                                className={`flex-1 relative z-10 text-sm font-medium py-2 transition-colors ${!isLogin ? 'text-white' : 'text-gray-400 hover:text-white'}`}
                            >
                                Sign Up
                            </button>
                        </div>

                        {/* Form */}
                        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                            <AnimatePresence mode="popLayout">
                                {!isLogin && (
                                    <MotionDiv
                                        initial={{ opacity: 0, height: 0 }}
                                        animate={{ opacity: 1, height: "auto" }}
                                        exit={{ opacity: 0, height: 0 }}
                                        className="overflow-hidden"
                                    >
                                        <div className="space-y-2">
                                            <label className="text-xs font-medium text-gray-300 ml-1">お名前</label>
                                            <input
                                                {...register("name")}
                                                type="text"
                                                placeholder="Starlist User"
                                                className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#227CFF] focus:border-transparent transition-all placeholder:text-gray-600"
                                            />
                                            {errors.name && (
                                                <p className="text-red-400 text-xs ml-1">{errors.name.message}</p>
                                            )}
                                        </div>
                                    </MotionDiv>
                                )}
                            </AnimatePresence>

                            <div className="space-y-2">
                                <label className="text-xs font-medium text-gray-300 ml-1">メールアドレス</label>
                                <input
                                    {...register("email")}
                                    type="email"
                                    placeholder="hello@example.com"
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#227CFF] focus:border-transparent transition-all placeholder:text-gray-600"
                                />
                                {errors.email && (
                                    <p className="text-red-400 text-xs ml-1">{errors.email.message}</p>
                                )}
                            </div>

                            <div className="space-y-2">
                                <label className="text-xs font-medium text-gray-300 ml-1">パスワード</label>
                                <input
                                    {...register("password")}
                                    type="password"
                                    placeholder="••••••••"
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#227CFF] focus:border-transparent transition-all placeholder:text-gray-600"
                                />
                                {errors.password && (
                                    <p className="text-red-400 text-xs ml-1">{errors.password.message}</p>
                                )}
                            </div>

                            <MotionButton
                                whileHover={{ scale: 1.02, boxShadow: "0 0 20px rgba(34, 124, 255, 0.4)" }}
                                whileTap={{ scale: 0.98 }}
                                type="submit"
                                disabled={isLoading}
                                className="w-full bg-[#227CFF] hover:bg-[#1b6ad6] text-white font-bold py-3 rounded-lg shadow-lg shadow-blue-900/20 transition-all flex items-center justify-center gap-2 mt-6"
                            >
                                {isLoading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : (
                                    <>
                                        <Mail className="w-4 h-4" />
                                        {isLogin ? "Continue with Email" : "Create Account"}
                                    </>
                                )}
                            </MotionButton>
                        </form>

                        {/* Divider */}
                        <div className="relative my-8">
                            <div className="absolute inset-0 flex items-center">
                                <div className="w-full border-t border-white/10"></div>
                            </div>
                            <div className="relative flex justify-center text-xs uppercase">
                                <span className="bg-[#050505] px-2 text-gray-500">Or continue with</span>
                            </div>
                        </div>

                        {/* Social Buttons */}
                        <div className="grid grid-cols-2 gap-4">
                            <button className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-white py-2.5 rounded-lg transition-all text-sm font-medium group">
                                <svg className="w-5 h-5" viewBox="0 0 24 24">
                                    <path
                                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                                        fill="#4285F4"
                                    />
                                    <path
                                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                                        fill="#34A853"
                                    />
                                    <path
                                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                                        fill="#FBBC05"
                                    />
                                    <path
                                        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                                        fill="#EA4335"
                                    />
                                </svg>
                                Google
                            </button>
                            <button className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-white py-2.5 rounded-lg transition-all text-sm font-medium">
                                <Github className="w-5 h-5" />
                                GitHub
                            </button>
                        </div>

                    </div>
                </div>
            </MotionDiv>
        </div>
    );
}
