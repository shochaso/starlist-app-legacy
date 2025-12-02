-- 投票・選択システムのためのテーブル追加
-- 作成日: 2025-06-22

-- Sポイント（投票通貨）テーブル
CREATE TABLE IF NOT EXISTS public.s_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    total_earned INTEGER NOT NULL DEFAULT 0,
    total_spent INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sポイント履歴テーブル
CREATE TABLE IF NOT EXISTS public.s_point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL, -- 正数：獲得、負数：使用
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earned', 'spent', 'bonus', 'refund')),
    source_type TEXT NOT NULL CHECK (source_type IN ('daily_login', 'voting', 'premium_question', 'purchase', 'admin')),
    source_id UUID, -- 関連するコンテンツやアクティビティのID
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2択投稿テーブル
CREATE TABLE IF NOT EXISTS public.voting_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_a_image_url TEXT,
    option_b_image_url TEXT,
    voting_cost INTEGER NOT NULL DEFAULT 1 CHECK (voting_cost > 0), -- Sポイント消費数
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    total_votes INTEGER DEFAULT 0,
    option_a_votes INTEGER DEFAULT 0,
    option_b_votes INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 投票履歴テーブル
CREATE TABLE IF NOT EXISTS public.votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voting_post_id UUID NOT NULL REFERENCES public.voting_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    selected_option TEXT NOT NULL CHECK (selected_option IN ('A', 'B')),
    s_points_spent INTEGER NOT NULL DEFAULT 1,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(voting_post_id, user_id) -- 1つの投稿に対して1人1票のみ
);

-- RLSポリシーの設定
ALTER TABLE public.s_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.s_point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voting_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- Sポイント関連のポリシー
CREATE POLICY "ユーザーは自分のSポイント残高を閲覧可能" ON public.s_points
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分のSポイント履歴を閲覧可能" ON public.s_point_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- 投稿関連のポリシー
CREATE POLICY "スターは自分の投票投稿を管理可能" ON public.voting_posts
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "アクティブな投票投稿は誰でも閲覧可能" ON public.voting_posts
    FOR SELECT USING (is_active = true);

-- 投票関連のポリシー
CREATE POLICY "ユーザーは投票を実行可能" ON public.votes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分の投票履歴を閲覧可能" ON public.votes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "スターは自分の投稿への投票を閲覧可能" ON public.votes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.voting_posts vp
            WHERE vp.id = voting_post_id AND vp.star_id = auth.uid()
        )
    );

-- トリガー関数：投票後の処理
CREATE OR REPLACE FUNCTION public.process_vote()
RETURNS TRIGGER AS $$
BEGIN
    -- 投票数更新
    IF NEW.selected_option = 'A' THEN
        UPDATE public.voting_posts 
        SET option_a_votes = option_a_votes + 1,
            total_votes = total_votes + 1,
            updated_at = NOW()
        WHERE id = NEW.voting_post_id;
    ELSE
        UPDATE public.voting_posts 
        SET option_b_votes = option_b_votes + 1,
            total_votes = total_votes + 1,
            updated_at = NOW()
        WHERE id = NEW.voting_post_id;
    END IF;

    -- Sポイント残高更新
    UPDATE public.s_points 
    SET balance = balance - NEW.s_points_spent,
        total_spent = total_spent + NEW.s_points_spent,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;

    -- Sポイント履歴記録
    INSERT INTO public.s_point_transactions (user_id, amount, transaction_type, source_type, source_id, description)
    VALUES (NEW.user_id, -NEW.s_points_spent, 'spent', 'voting', NEW.voting_post_id, '投票に参加');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER process_vote_trigger
    AFTER INSERT ON public.votes
    FOR EACH ROW EXECUTE FUNCTION public.process_vote();

-- 初期Sポイント付与のトリガー関数
CREATE OR REPLACE FUNCTION public.grant_initial_s_points()
RETURNS TRIGGER AS $$
BEGIN
    -- 新規ユーザーに100Sポイント付与
    INSERT INTO public.s_points (user_id, balance, total_earned)
    VALUES (NEW.id, 100, 100);
    
    INSERT INTO public.s_point_transactions (user_id, amount, transaction_type, source_type, description)
    VALUES (NEW.id, 100, 'bonus', 'admin', '新規登録ボーナス');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER grant_initial_s_points_trigger
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.grant_initial_s_points();

-- RPC関数：Sポイント残高取得
CREATE OR REPLACE FUNCTION public.get_s_point_balance(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_balance INTEGER;
BEGIN
    SELECT balance INTO current_balance
    FROM public.s_points
    WHERE user_id = target_user_id;
    
    RETURN COALESCE(current_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC関数：投票実行
CREATE OR REPLACE FUNCTION public.cast_vote(
    p_voting_post_id UUID,
    p_selected_option TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_voting_cost INTEGER;
    v_current_balance INTEGER;
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_is_active BOOLEAN;
BEGIN
    -- 認証チェック
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- 投票投稿の情報取得
    SELECT voting_cost, expires_at, is_active
    INTO v_voting_cost, v_expires_at, v_is_active
    FROM public.voting_posts
    WHERE id = p_voting_post_id;

    -- 投稿存在チェック
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voting post not found');
    END IF;

    -- アクティブチェック
    IF NOT v_is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voting is not active');
    END IF;

    -- 期限チェック
    IF v_expires_at IS NOT NULL AND v_expires_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voting has expired');
    END IF;

    -- 重複投票チェック
    IF EXISTS (SELECT 1 FROM public.votes WHERE voting_post_id = p_voting_post_id AND user_id = v_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already voted');
    END IF;

    -- Sポイント残高チェック
    SELECT balance INTO v_current_balance
    FROM public.s_points
    WHERE user_id = v_user_id;

    IF v_current_balance < v_voting_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient S-points');
    END IF;

    -- 投票実行
    INSERT INTO public.votes (voting_post_id, user_id, selected_option, s_points_spent)
    VALUES (p_voting_post_id, v_user_id, p_selected_option, v_voting_cost);

    RETURN jsonb_build_object('success', true, 'message', 'Vote cast successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;