-- スターポイント関連テーブルの作成
-- 2025-07-16

-- スターポイント残高テーブル
CREATE TABLE IF NOT EXISTS public.s_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
  total_earned INTEGER NOT NULL DEFAULT 0 CHECK (total_earned >= 0),
  total_spent INTEGER NOT NULL DEFAULT 0 CHECK (total_spent >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id)
);

-- スターポイント取引履歴テーブル
CREATE TABLE IF NOT EXISTS public.s_point_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('earned', 'spent', 'bonus', 'refund')),
  amount INTEGER NOT NULL CHECK (amount > 0),
  source TEXT NOT NULL,
  source_type TEXT NOT NULL CHECK (source_type IN ('dailyLogin', 'voting', 'premiumQuestion', 'purchase', 'admin')),
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_s_points_user_id ON public.s_points(user_id);
CREATE INDEX IF NOT EXISTS idx_s_point_transactions_user_id ON public.s_point_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_s_point_transactions_created_at ON public.s_point_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_s_point_transactions_type ON public.s_point_transactions(transaction_type);

-- RLS（Row Level Security）の有効化
ALTER TABLE public.s_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.s_point_transactions ENABLE ROW LEVEL SECURITY;

-- s_pointsテーブルのポリシー
CREATE POLICY "Users can view their own star point balance" ON public.s_points
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own star point balance" ON public.s_points
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own star point balance" ON public.s_points
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- s_point_transactionsテーブルのポリシー
CREATE POLICY "Users can view their own star point transactions" ON public.s_point_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own star point transactions" ON public.s_point_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 更新日時トリガーの作成
CREATE OR REPLACE FUNCTION public.update_s_points_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_s_points_updated_at
  BEFORE UPDATE ON public.s_points
  FOR EACH ROW EXECUTE FUNCTION public.update_s_points_updated_at();

-- 初期データの挿入（テスト用）
-- 注意: 本番環境では削除してください
INSERT INTO public.s_points (user_id, balance, total_earned, total_spent)
SELECT 
  id,
  1000, -- 初期残高
  1000, -- 初期獲得額
  0     -- 初期使用額
FROM public.profiles
WHERE NOT EXISTS (SELECT 1 FROM public.s_points WHERE s_points.user_id = profiles.id); 