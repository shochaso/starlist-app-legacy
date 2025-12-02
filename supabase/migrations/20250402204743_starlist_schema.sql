-- Starlistアプリケーションのデータベーススキーマ
-- ER図設計書に基づいた実装: 2025-04-02

-- プロフィールテーブルの更新（既存テーブルの拡張）
-- usersはビューなので、profilesテーブルに追加
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'suspended'));

-- スタープロフィールテーブル
CREATE TABLE IF NOT EXISTS public.star_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('entertainer', 'athlete', 'creator', 'vtuber', 'musician', 'actor', 'other')),
  description TEXT,
  paid_follower_count INTEGER DEFAULT 0,
  star_rank TEXT DEFAULT 'regular' CHECK (star_rank IN ('regular', 'platinum', 'super')),
  revenue_share_rate DECIMAL(5,2) DEFAULT 80.00 CHECK (revenue_share_rate BETWEEN 0 AND 100),
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id)
);

-- コンテンツテーブル
CREATE TABLE IF NOT EXISTS public.contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('video', 'image', 'text', 'link')),
  url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_published BOOLEAN DEFAULT TRUE,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- コンテンツ消費テーブル
CREATE TABLE IF NOT EXISTS public.content_consumptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('youtube', 'spotify', 'netflix', 'book', 'product', 'other')),
  content_id TEXT,
  title TEXT NOT NULL,
  description TEXT,
  platform TEXT,
  url TEXT,
  consumption_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  duration INTEGER,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_public BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- サブスクリプションプランテーブル
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'JPY',
  interval TEXT NOT NULL CHECK (interval IN ('monthly', 'yearly')),
  features JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- サブスクリプションテーブル
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE RESTRICT,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  auto_renew BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (end_date > start_date)
);

-- チケットテーブル
CREATE TABLE IF NOT EXISTS public.tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('bronze', 'silver', 'gold')),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  expiry_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- チケット使用履歴テーブル
CREATE TABLE IF NOT EXISTS public.ticket_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_id UUID NOT NULL REFERENCES public.contents(id) ON DELETE CASCADE,
  used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- コメントテーブル（既存テーブルの代わりに新しいスキーマに沿ったテーブル）
DROP TABLE IF EXISTS public.comments;
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL REFERENCES public.contents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  likes INTEGER DEFAULT 0,
  is_hidden BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- いいねテーブル
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_id UUID REFERENCES public.contents(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (
    (content_id IS NOT NULL AND comment_id IS NULL) OR
    (content_id IS NULL AND comment_id IS NOT NULL)
  ),
  UNIQUE (user_id, content_id),
  UNIQUE (user_id, comment_id)
);

-- フォローテーブル（既存テーブルの確認と調整）
-- 既存のフォローテーブルを使用するため、テーブル作成は省略

-- 通知テーブル
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('new_content', 'new_comment', 'new_follower', 'new_like', 'system', 'other')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 支払いテーブル
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'JPY',
  status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT NOT NULL,
  transaction_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 分析データテーブル
CREATE TABLE IF NOT EXISTS public.analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_data JSONB DEFAULT '{}'::jsonb,
  device_info JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- トリガー：コンテンツのいいね数更新
CREATE OR REPLACE FUNCTION public.update_content_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.content_id IS NOT NULL THEN
    UPDATE public.contents SET likes = likes + 1 WHERE id = NEW.content_id;
  ELSIF TG_OP = 'DELETE' AND OLD.content_id IS NOT NULL THEN
    UPDATE public.contents SET likes = GREATEST(0, likes - 1) WHERE id = OLD.content_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_content_likes
  AFTER INSERT OR DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.update_content_likes();

-- トリガー：コメントのいいね数更新
CREATE OR REPLACE FUNCTION public.update_comment_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.comment_id IS NOT NULL THEN
    UPDATE public.comments SET likes = likes + 1 WHERE id = NEW.comment_id;
  ELSIF TG_OP = 'DELETE' AND OLD.comment_id IS NOT NULL THEN
    UPDATE public.comments SET likes = GREATEST(0, likes - 1) WHERE id = OLD.comment_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_comment_likes
  AFTER INSERT OR DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.update_comment_likes();

-- トリガー：コンテンツのコメント数更新
CREATE OR REPLACE FUNCTION public.update_content_comments()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NULL THEN
    UPDATE public.contents SET comments = comments + 1 WHERE id = NEW.content_id;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NULL THEN
    UPDATE public.contents SET comments = GREATEST(0, comments - 1) WHERE id = OLD.content_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_content_comments
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.update_content_comments();

-- トリガー：スタープロフィールの有料フォロワー数更新
CREATE OR REPLACE FUNCTION public.update_paid_follower_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' THEN
    UPDATE public.star_profiles
    SET paid_follower_count = paid_follower_count + 1
    WHERE user_id = NEW.star_id;
  ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.status = 'active' AND NEW.status != 'active') THEN
    UPDATE public.star_profiles
    SET paid_follower_count = GREATEST(0, paid_follower_count - 1)
    WHERE user_id = CASE WHEN TG_OP = 'DELETE' THEN OLD.star_id ELSE NEW.star_id END;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_paid_follower_count
  AFTER INSERT OR UPDATE OR DELETE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_paid_follower_count();

-- すべてのテーブルに行レベルセキュリティを有効化
ALTER TABLE public.star_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_consumptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics ENABLE ROW LEVEL SECURITY;

-- RLSポリシーの設定
-- スタープロフィール
CREATE POLICY "スターは自分のプロフィールを管理可能" ON public.star_profiles
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "誰でもスタープロフィールを閲覧可能" ON public.star_profiles
  FOR SELECT USING (true);

-- コンテンツ
CREATE POLICY "スターは自分のコンテンツを管理可能" ON public.contents
  FOR ALL USING (auth.uid() = author_id);
CREATE POLICY "公開コンテンツは誰でも閲覧可能" ON public.contents
  FOR SELECT USING (is_published = true);

-- コンテンツ消費
CREATE POLICY "スターは自分の消費データを管理可能" ON public.content_consumptions
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "公開消費データは誰でも閲覧可能" ON public.content_consumptions
  FOR SELECT USING (is_public = true);

-- サブスクリプションプラン
CREATE POLICY "管理者のみプランを管理可能" ON public.subscription_plans
  FOR ALL USING (false);
CREATE POLICY "誰でもプランを閲覧可能" ON public.subscription_plans
  FOR SELECT USING (is_active = true);

-- サブスクリプション
CREATE POLICY "ユーザーは自分のサブスクリプションを管理可能" ON public.subscriptions
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "スターは自分への購読を閲覧可能" ON public.subscriptions
  FOR SELECT USING (auth.uid() = star_id);

-- チケット
CREATE POLICY "ユーザーは自分のチケットを管理可能" ON public.tickets
  FOR ALL USING (auth.uid() = user_id);

-- チケット使用履歴
CREATE POLICY "ユーザーは自分のチケット使用履歴を閲覧可能" ON public.ticket_usages
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "スターは自分のコンテンツのチケット使用履歴を閲覧可能" ON public.ticket_usages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.contents c
      WHERE c.id = content_id AND c.author_id = auth.uid()
    )
  );

-- コメント
CREATE POLICY "ユーザーは自分のコメントを管理可能" ON public.comments
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "非表示でないコメントは誰でも閲覧可能" ON public.comments
  FOR SELECT USING (is_hidden = false);
CREATE POLICY "コンテンツ作成者はコメントを管理可能" ON public.comments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.contents c
      WHERE c.id = content_id AND c.author_id = auth.uid()
    )
  );

-- いいね
CREATE POLICY "ユーザーは自分のいいねを管理可能" ON public.likes
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "いいねは誰でも閲覧可能" ON public.likes
  FOR SELECT USING (true);

-- 通知
CREATE POLICY "ユーザーは自分の通知を管理可能" ON public.notifications
  FOR ALL USING (auth.uid() = user_id);

-- 支払い
CREATE POLICY "ユーザーは自分の支払いを閲覧可能" ON public.payments
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "スターは自分に関連する支払いを閲覧可能" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.id = subscription_id AND s.star_id = auth.uid()
    )
  );

-- 分析データ
CREATE POLICY "管理者のみ分析データを閲覧可能" ON public.analytics
  FOR SELECT USING (false);
CREATE POLICY "ユーザーは自分の分析データを閲覧可能" ON public.analytics
  FOR SELECT USING (auth.uid() = user_id);

-- ユーザーは、スターの場合、スタープロフィールを自動作成するトリガー
CREATE OR REPLACE FUNCTION public.create_star_profile()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'star' AND (OLD.role IS NULL OR OLD.role != 'star') THEN
    INSERT INTO public.star_profiles (user_id, category)
    VALUES (NEW.id, 'other')
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER create_star_profile
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW 
  WHEN (NEW.role = 'star' AND (OLD.role IS NULL OR OLD.role != 'star'))
  EXECUTE FUNCTION public.create_star_profile(); 