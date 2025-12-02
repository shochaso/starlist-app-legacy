-- Super Chat風オプション課金システムのためのテーブル追加
-- 作成日: 2025-06-22

-- Super Chatメッセージテーブル
CREATE TABLE IF NOT EXISTS public.super_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content_id UUID REFERENCES public.contents(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    amount INTEGER NOT NULL CHECK (amount > 0),
    currency TEXT DEFAULT 'SPT' CHECK (currency IN ('SPT', 'JPY', 'USD')),
    tier_level INTEGER NOT NULL DEFAULT 1 CHECK (tier_level BETWEEN 1 AND 5),
    background_color TEXT DEFAULT '#1976D2',
    text_color TEXT DEFAULT '#FFFFFF',
    is_pinned BOOLEAN DEFAULT FALSE,
    pin_duration_minutes INTEGER DEFAULT 5,
    pinned_until TIMESTAMP WITH TIME ZONE,
    is_highlighted BOOLEAN DEFAULT TRUE,
    visibility_duration_minutes INTEGER DEFAULT 60,
    visible_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '60 minutes'),
    star_reply TEXT,
    star_replied_at TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT FALSE,
    s_points_spent INTEGER NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Super Chat料金設定テーブル
CREATE TABLE IF NOT EXISTS public.super_chat_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT TRUE,
    min_amount INTEGER DEFAULT 100 CHECK (min_amount > 0),
    max_amount INTEGER DEFAULT 10000 CHECK (max_amount > min_amount),
    tier_1_threshold INTEGER DEFAULT 100,
    tier_1_duration INTEGER DEFAULT 5, -- minutes
    tier_1_color TEXT DEFAULT '#1976D2',
    tier_2_threshold INTEGER DEFAULT 500,
    tier_2_duration INTEGER DEFAULT 15,
    tier_2_color TEXT DEFAULT '#9C27B0',
    tier_3_threshold INTEGER DEFAULT 1000,
    tier_3_duration INTEGER DEFAULT 30,
    tier_3_color TEXT DEFAULT '#FF9800',
    tier_4_threshold INTEGER DEFAULT 2500,
    tier_4_duration INTEGER DEFAULT 60,
    tier_4_color TEXT DEFAULT '#F44336',
    tier_5_threshold INTEGER DEFAULT 5000,
    tier_5_duration INTEGER DEFAULT 120,
    tier_5_color TEXT DEFAULT '#FFD700',
    revenue_share_rate DECIMAL(5,2) DEFAULT 80.00 CHECK (revenue_share_rate BETWEEN 0 AND 100),
    auto_reply_enabled BOOLEAN DEFAULT FALSE,
    auto_reply_message TEXT,
    moderation_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(star_id)
);

-- Super Chatイベントテーブル（ライブ配信やイベント用）
CREATE TABLE IF NOT EXISTS public.super_chat_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT DEFAULT 'live_stream' CHECK (event_type IN ('live_stream', 'special_event', 'milestone', 'qa_session')),
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    total_earnings INTEGER DEFAULT 0,
    message_count INTEGER DEFAULT 0,
    top_supporter_id UUID REFERENCES public.profiles(id),
    top_support_amount INTEGER DEFAULT 0,
    special_multiplier DECIMAL(3,2) DEFAULT 1.00,
    goal_amount INTEGER,
    goal_description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Super Chat統計テーブル
CREATE TABLE IF NOT EXISTS public.super_chat_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_earnings INTEGER DEFAULT 0,
    message_count INTEGER DEFAULT 0,
    unique_supporters INTEGER DEFAULT 0,
    average_amount DECIMAL(10,2) DEFAULT 0,
    top_amount INTEGER DEFAULT 0,
    tier_1_count INTEGER DEFAULT 0,
    tier_2_count INTEGER DEFAULT 0,
    tier_3_count INTEGER DEFAULT 0,
    tier_4_count INTEGER DEFAULT 0,
    tier_5_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(star_id, date)
);

-- RLSポリシーの設定
ALTER TABLE public.super_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.super_chat_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.super_chat_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.super_chat_statistics ENABLE ROW LEVEL SECURITY;

-- Super Chatメッセージのポリシー
CREATE POLICY "送信者は自分のSuper Chatを閲覧可能" ON public.super_chat_messages
    FOR SELECT USING (auth.uid() = sender_id);

CREATE POLICY "スターは自分へのSuper Chatを管理可能" ON public.super_chat_messages
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "公開Super Chatは誰でも閲覧可能" ON public.super_chat_messages
    FOR SELECT USING (visible_until > NOW());

-- Super Chat料金設定のポリシー
CREATE POLICY "スターは自分の料金設定を管理可能" ON public.super_chat_pricing
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "料金設定は誰でも閲覧可能" ON public.super_chat_pricing
    FOR SELECT USING (true);

-- Super Chatイベントのポリシー
CREATE POLICY "スターは自分のイベントを管理可能" ON public.super_chat_events
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "アクティブイベントは誰でも閲覧可能" ON public.super_chat_events
    FOR SELECT USING (is_active = true);

-- Super Chat統計のポリシー
CREATE POLICY "スターは自分の統計を閲覧可能" ON public.super_chat_statistics
    FOR SELECT USING (auth.uid() = star_id);

-- Super Chatメッセージを送信する関数
CREATE OR REPLACE FUNCTION public.send_super_chat_message(
    p_sender_id UUID,
    p_star_id UUID,
    p_message TEXT,
    p_amount INTEGER,
    p_content_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_pricing RECORD;
    v_sender_balance INTEGER;
    v_tier_level INTEGER;
    v_background_color TEXT;
    v_pin_duration INTEGER;
    v_visibility_duration INTEGER;
    v_message_id UUID;
    v_event RECORD;
    v_special_multiplier DECIMAL(3,2) := 1.00;
    v_final_amount INTEGER;
BEGIN
    -- 認証チェック
    IF auth.uid() != p_sender_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- スターの料金設定を取得
    SELECT * INTO v_pricing
    FROM public.super_chat_pricing
    WHERE star_id = p_star_id;

    IF NOT FOUND OR NOT v_pricing.is_enabled THEN
        RETURN jsonb_build_object('success', false, 'error', 'Super Chat not enabled for this star');
    END IF;

    -- 金額の妥当性チェック
    IF p_amount < v_pricing.min_amount OR p_amount > v_pricing.max_amount THEN
        RETURN jsonb_build_object('success', false, 'error', format('Amount must be between %s and %s SP', v_pricing.min_amount, v_pricing.max_amount));
    END IF;

    -- アクティブなイベントがあるかチェック
    SELECT * INTO v_event
    FROM public.super_chat_events
    WHERE star_id = p_star_id
    AND is_active = true
    AND (end_time IS NULL OR end_time > NOW())
    ORDER BY start_time DESC
    LIMIT 1;

    IF FOUND THEN
        v_special_multiplier := v_event.special_multiplier;
    END IF;

    v_final_amount := (p_amount * v_special_multiplier)::INTEGER;

    -- Sポイント残高をチェック
    SELECT balance INTO v_sender_balance
    FROM public.s_points
    WHERE user_id = p_sender_id;

    IF v_sender_balance < v_final_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient S-points');
    END IF;

    -- ティアレベルと設定を決定
    IF p_amount >= v_pricing.tier_5_threshold THEN
        v_tier_level := 5;
        v_background_color := v_pricing.tier_5_color;
        v_pin_duration := v_pricing.tier_5_duration;
        v_visibility_duration := v_pricing.tier_5_duration;
    ELSIF p_amount >= v_pricing.tier_4_threshold THEN
        v_tier_level := 4;
        v_background_color := v_pricing.tier_4_color;
        v_pin_duration := v_pricing.tier_4_duration;
        v_visibility_duration := v_pricing.tier_4_duration;
    ELSIF p_amount >= v_pricing.tier_3_threshold THEN
        v_tier_level := 3;
        v_background_color := v_pricing.tier_3_color;
        v_pin_duration := v_pricing.tier_3_duration;
        v_visibility_duration := v_pricing.tier_3_duration;
    ELSIF p_amount >= v_pricing.tier_2_threshold THEN
        v_tier_level := 2;
        v_background_color := v_pricing.tier_2_color;
        v_pin_duration := v_pricing.tier_2_duration;
        v_visibility_duration := v_pricing.tier_2_duration;
    ELSE
        v_tier_level := 1;
        v_background_color := v_pricing.tier_1_color;
        v_pin_duration := v_pricing.tier_1_duration;
        v_visibility_duration := v_pricing.tier_1_duration;
    END IF;

    -- Super Chatメッセージを作成
    INSERT INTO public.super_chat_messages (
        sender_id,
        star_id,
        content_id,
        message,
        amount,
        tier_level,
        background_color,
        pin_duration_minutes,
        pinned_until,
        visibility_duration_minutes,
        visible_until,
        s_points_spent,
        is_pinned,
        metadata
    ) VALUES (
        p_sender_id,
        p_star_id,
        p_content_id,
        p_message,
        p_amount,
        v_tier_level,
        v_background_color,
        v_pin_duration,
        NOW() + INTERVAL '1 minute' * v_pin_duration,
        v_visibility_duration,
        NOW() + INTERVAL '1 minute' * v_visibility_duration,
        v_final_amount,
        v_tier_level >= 3, -- Tier 3以上は自動でピン留め
        jsonb_build_object(
            'event_id', v_event.id,
            'special_multiplier', v_special_multiplier,
            'original_amount', p_amount
        )
    ) RETURNING id INTO v_message_id;

    -- Sポイントを消費
    UPDATE public.s_points
    SET balance = balance - v_final_amount,
        total_spent = total_spent + v_final_amount,
        updated_at = NOW()
    WHERE user_id = p_sender_id;

    -- Sポイント取引履歴を記録
    INSERT INTO public.s_point_transactions (
        user_id,
        amount,
        transaction_type,
        source_type,
        source_id,
        description
    ) VALUES (
        p_sender_id,
        -v_final_amount,
        'spent',
        'super_chat',
        v_message_id,
        'Super Chatメッセージを送信'
    );

    -- イベント統計を更新
    IF v_event.id IS NOT NULL THEN
        UPDATE public.super_chat_events
        SET total_earnings = total_earnings + v_final_amount,
            message_count = message_count + 1,
            updated_at = NOW()
        WHERE id = v_event.id;

        -- トップサポーターを更新
        IF v_final_amount > v_event.top_support_amount THEN
            UPDATE public.super_chat_events
            SET top_supporter_id = p_sender_id,
                top_support_amount = v_final_amount
            WHERE id = v_event.id;
        END IF;
    END IF;

    -- 統計を更新
    INSERT INTO public.super_chat_statistics (
        star_id,
        date,
        total_earnings,
        message_count,
        unique_supporters,
        average_amount,
        top_amount
    ) VALUES (
        p_star_id,
        CURRENT_DATE,
        v_final_amount,
        1,
        1,
        v_final_amount,
        v_final_amount
    )
    ON CONFLICT (star_id, date)
    DO UPDATE SET
        total_earnings = super_chat_statistics.total_earnings + v_final_amount,
        message_count = super_chat_statistics.message_count + 1,
        average_amount = (super_chat_statistics.total_earnings + v_final_amount) / (super_chat_statistics.message_count + 1),
        top_amount = GREATEST(super_chat_statistics.top_amount, v_final_amount),
        updated_at = NOW();

    -- ティア別カウントを更新
    EXECUTE format('UPDATE public.super_chat_statistics SET tier_%s_count = tier_%s_count + 1 WHERE star_id = $1 AND date = CURRENT_DATE', v_tier_level, v_tier_level) USING p_star_id;

    -- スターに通知
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        data
    ) VALUES (
        p_star_id,
        'super_chat',
        'Super Chat',
        format('%s SPのSuper Chatが届きました！', v_final_amount),
        jsonb_build_object(
            'message_id', v_message_id,
            'amount', v_final_amount,
            'tier_level', v_tier_level
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'message_id', v_message_id,
        'tier_level', v_tier_level,
        'amount_spent', v_final_amount,
        'pin_duration', v_pin_duration,
        'background_color', v_background_color
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Super Chat料金設定を更新する関数
CREATE OR REPLACE FUNCTION public.update_super_chat_pricing(
    p_star_id UUID,
    p_is_enabled BOOLEAN,
    p_min_amount INTEGER,
    p_max_amount INTEGER,
    p_revenue_share_rate DECIMAL
)
RETURNS JSONB AS $$
BEGIN
    -- 認証チェック
    IF auth.uid() != p_star_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 設定を更新または作成
    INSERT INTO public.super_chat_pricing (
        star_id,
        is_enabled,
        min_amount,
        max_amount,
        revenue_share_rate,
        updated_at
    ) VALUES (
        p_star_id,
        p_is_enabled,
        p_min_amount,
        p_max_amount,
        p_revenue_share_rate,
        NOW()
    )
    ON CONFLICT (star_id)
    DO UPDATE SET
        is_enabled = EXCLUDED.is_enabled,
        min_amount = EXCLUDED.min_amount,
        max_amount = EXCLUDED.max_amount,
        revenue_share_rate = EXCLUDED.revenue_share_rate,
        updated_at = NOW();

    RETURN jsonb_build_object('success', true, 'message', 'Super Chat pricing updated successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Super Chatイベントを作成する関数
CREATE OR REPLACE FUNCTION public.create_super_chat_event(
    p_star_id UUID,
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_event_type TEXT DEFAULT 'live_stream',
    p_end_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_special_multiplier DECIMAL DEFAULT 1.00,
    p_goal_amount INTEGER DEFAULT NULL,
    p_goal_description TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_event_id UUID;
BEGIN
    -- 認証チェック
    IF auth.uid() != p_star_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 既存のアクティブイベントを終了
    UPDATE public.super_chat_events
    SET is_active = false,
        end_time = NOW(),
        updated_at = NOW()
    WHERE star_id = p_star_id
    AND is_active = true
    AND (end_time IS NULL OR end_time > NOW());

    -- 新しいイベントを作成
    INSERT INTO public.super_chat_events (
        star_id,
        title,
        description,
        event_type,
        end_time,
        special_multiplier,
        goal_amount,
        goal_description
    ) VALUES (
        p_star_id,
        p_title,
        p_description,
        p_event_type,
        p_end_time,
        p_special_multiplier,
        p_goal_amount,
        p_goal_description
    ) RETURNING id INTO v_event_id;

    RETURN jsonb_build_object(
        'success', true,
        'event_id', v_event_id,
        'message', 'Super Chat event created successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 期限切れSuper Chatの自動処理関数
CREATE OR REPLACE FUNCTION public.cleanup_expired_super_chats()
RETURNS VOID AS $$
BEGIN
    -- ピン留め期限切れのメッセージを非ピン化
    UPDATE public.super_chat_messages
    SET is_pinned = false,
        updated_at = NOW()
    WHERE is_pinned = true
    AND pinned_until < NOW();

    -- 表示期限切れのメッセージを非表示化
    UPDATE public.super_chat_messages
    SET is_highlighted = false,
        updated_at = NOW()
    WHERE is_highlighted = true
    AND visible_until < NOW();

    -- 終了時刻を過ぎたイベントを非アクティブ化
    UPDATE public.super_chat_events
    SET is_active = false,
        updated_at = NOW()
    WHERE is_active = true
    AND end_time IS NOT NULL
    AND end_time < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_super_chat_messages_star_id ON public.super_chat_messages(star_id);
CREATE INDEX IF NOT EXISTS idx_super_chat_messages_sender_id ON public.super_chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_super_chat_messages_visible_until ON public.super_chat_messages(visible_until);
CREATE INDEX IF NOT EXISTS idx_super_chat_messages_pinned_until ON public.super_chat_messages(pinned_until);
CREATE INDEX IF NOT EXISTS idx_super_chat_events_star_id ON public.super_chat_events(star_id);
CREATE INDEX IF NOT EXISTS idx_super_chat_statistics_star_date ON public.super_chat_statistics(star_id, date);