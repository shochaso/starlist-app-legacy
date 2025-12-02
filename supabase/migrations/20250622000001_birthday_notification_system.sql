-- 誕生日通知システムのためのテーブル追加
-- 作成日: 2025-06-22

-- プロフィールテーブル拡張（誕生日情報）
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birthday DATE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birthday_visibility TEXT DEFAULT 'followers' CHECK (birthday_visibility IN ('public', 'followers', 'private'));
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birthday_notification_enabled BOOLEAN DEFAULT TRUE;

-- 誕生日通知設定テーブル
CREATE TABLE IF NOT EXISTS public.birthday_notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT TRUE,
    custom_message TEXT,
    notification_days_before INTEGER DEFAULT 0 CHECK (notification_days_before >= 0 AND notification_days_before <= 30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, star_id)
);

-- 誕生日通知履歴テーブル
CREATE TABLE IF NOT EXISTS public.birthday_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notified_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('birthday_today', 'birthday_upcoming', 'custom')),
    message TEXT NOT NULL,
    birthday_date DATE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 誕生日イベントテーブル（特別なお祝いイベント用）
CREATE TABLE IF NOT EXISTS public.birthday_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    is_milestone BOOLEAN DEFAULT FALSE,
    age INTEGER,
    special_rewards JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLSポリシーの設定
ALTER TABLE public.birthday_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.birthday_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.birthday_events ENABLE ROW LEVEL SECURITY;

-- 誕生日通知設定のポリシー
CREATE POLICY "ユーザーは自分の誕生日通知設定を管理可能" ON public.birthday_notification_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "スターは自分への誕生日通知設定を閲覧可能" ON public.birthday_notification_settings
    FOR SELECT USING (auth.uid() = star_id);

-- 誕生日通知のポリシー
CREATE POLICY "ユーザーは自分の誕生日通知を閲覧可能" ON public.birthday_notifications
    FOR SELECT USING (auth.uid() = notified_user_id);

CREATE POLICY "スターは自分の誕生日通知を管理可能" ON public.birthday_notifications
    FOR ALL USING (auth.uid() = star_id);

-- 誕生日イベントのポリシー
CREATE POLICY "スターは自分の誕生日イベントを管理可能" ON public.birthday_events
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "アクティブな誕生日イベントは誰でも閲覧可能" ON public.birthday_events
    FOR SELECT USING (is_active = true);

-- 誕生日通知を送信する関数
CREATE OR REPLACE FUNCTION public.send_birthday_notification(
    p_star_id UUID,
    p_notification_type TEXT,
    p_custom_message TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_star_birthday DATE;
    v_star_name TEXT;
    v_notification_message TEXT;
    v_followers_cursor CURSOR FOR 
        SELECT f.follower_id, bns.custom_message, bns.notification_days_before
        FROM public.follows f
        LEFT JOIN public.birthday_notification_settings bns ON f.follower_id = bns.user_id AND f.following_id = bns.star_id
        WHERE f.following_id = p_star_id
        AND (bns.notification_enabled IS NULL OR bns.notification_enabled = true);
    v_notification_count INTEGER := 0;
BEGIN
    -- スターの誕生日と名前を取得
    SELECT birthday, full_name INTO v_star_birthday, v_star_name
    FROM public.profiles
    WHERE id = p_star_id;

    IF v_star_birthday IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Star birthday not set');
    END IF;

    -- 通知メッセージを構築
    IF p_custom_message IS NOT NULL THEN
        v_notification_message := p_custom_message;
    ELSE
        CASE p_notification_type
            WHEN 'birthday_today' THEN
                v_notification_message := v_star_name || 'さん、お誕生日おめでとうございます！🎉';
            WHEN 'birthday_upcoming' THEN
                v_notification_message := v_star_name || 'さんの誕生日が近づいています！';
            ELSE
                v_notification_message := v_star_name || 'さんからのお知らせです。';
        END CASE;
    END IF;

    -- フォロワーに通知を送信
    FOR v_follower IN v_followers_cursor LOOP
        -- カスタムメッセージがある場合は使用
        IF v_follower.custom_message IS NOT NULL THEN
            v_notification_message := v_follower.custom_message;
        END IF;

        -- 誕生日通知を挿入
        INSERT INTO public.birthday_notifications (
            star_id, 
            notified_user_id, 
            notification_type, 
            message, 
            birthday_date
        ) VALUES (
            p_star_id,
            v_follower.follower_id,
            p_notification_type,
            v_notification_message,
            v_star_birthday
        );

        -- 通常の通知テーブルにも挿入
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            data
        ) VALUES (
            v_follower.follower_id,
            'birthday',
            '誕生日のお知らせ',
            v_notification_message,
            jsonb_build_object(
                'star_id', p_star_id,
                'star_name', v_star_name,
                'birthday_date', v_star_birthday,
                'notification_type', p_notification_type
            )
        );

        v_notification_count := v_notification_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true, 
        'notifications_sent', v_notification_count,
        'message', 'Birthday notifications sent successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 今日が誕生日のスターを取得する関数
CREATE OR REPLACE FUNCTION public.get_birthday_stars_today()
RETURNS TABLE(
    star_id UUID,
    star_name TEXT,
    birthday DATE,
    age INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.birthday,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birthday))::INTEGER
    FROM public.profiles u
    WHERE u.role = 'star'
    AND u.birthday IS NOT NULL
    AND EXTRACT(MONTH FROM u.birthday) = EXTRACT(MONTH FROM CURRENT_DATE)
    AND EXTRACT(DAY FROM u.birthday) = EXTRACT(DAY FROM CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 近日中に誕生日を迎えるスターを取得する関数
CREATE OR REPLACE FUNCTION public.get_upcoming_birthday_stars(days_ahead INTEGER DEFAULT 7)
RETURNS TABLE(
    star_id UUID,
    star_name TEXT,
    birthday DATE,
    days_until_birthday INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.birthday,
        CASE
            WHEN EXTRACT(DOY FROM u.birthday) >= EXTRACT(DOY FROM CURRENT_DATE) THEN
                EXTRACT(DOY FROM u.birthday)::INTEGER - EXTRACT(DOY FROM CURRENT_DATE)::INTEGER
            ELSE
                (365 + EXTRACT(DOY FROM u.birthday)::INTEGER - EXTRACT(DOY FROM CURRENT_DATE)::INTEGER) % 365
        END
    FROM public.profiles u
    WHERE u.role = 'star'
    AND u.birthday IS NOT NULL
    AND (
        CASE
            WHEN EXTRACT(DOY FROM u.birthday) >= EXTRACT(DOY FROM CURRENT_DATE) THEN
                EXTRACT(DOY FROM u.birthday)::INTEGER - EXTRACT(DOY FROM CURRENT_DATE)::INTEGER
            ELSE
                (365 + EXTRACT(DOY FROM u.birthday)::INTEGER - EXTRACT(DOY FROM CURRENT_DATE)::INTEGER) % 365
        END
    ) BETWEEN 1 AND days_ahead
    ORDER BY 4 ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 誕生日通知設定を更新する関数
CREATE OR REPLACE FUNCTION public.update_birthday_notification_setting(
    p_user_id UUID,
    p_star_id UUID,
    p_notification_enabled BOOLEAN,
    p_custom_message TEXT DEFAULT NULL,
    p_notification_days_before INTEGER DEFAULT 0
)
RETURNS JSONB AS $$
BEGIN
    INSERT INTO public.birthday_notification_settings (
        user_id,
        star_id,
        notification_enabled,
        custom_message,
        notification_days_before,
        updated_at
    ) VALUES (
        p_user_id,
        p_star_id,
        p_notification_enabled,
        p_custom_message,
        p_notification_days_before,
        NOW()
    )
    ON CONFLICT (user_id, star_id)
    DO UPDATE SET
        notification_enabled = EXCLUDED.notification_enabled,
        custom_message = EXCLUDED.custom_message,
        notification_days_before = EXCLUDED.notification_days_before,
        updated_at = NOW();

    RETURN jsonb_build_object('success', true, 'message', 'Notification setting updated');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 毎日実行される誕生日チェック関数（cron job用）
CREATE OR REPLACE FUNCTION public.daily_birthday_check()
RETURNS VOID AS $$
DECLARE
    v_star RECORD;
BEGIN
    -- 今日が誕生日のスターに対して通知を送信
    FOR v_star IN SELECT * FROM public.get_birthday_stars_today() LOOP
        PERFORM public.send_birthday_notification(
            v_star.star_id,
            'birthday_today'
        );
    END LOOP;

    -- 近日中に誕生日を迎えるスターに対して事前通知を送信
    FOR v_star IN 
        SELECT 
            gubs.star_id,
            bns.notification_days_before
        FROM public.get_upcoming_birthday_stars(30) gubs
        JOIN public.birthday_notification_settings bns ON gubs.star_id = bns.star_id
        WHERE gubs.days_until_birthday = bns.notification_days_before
        AND bns.notification_enabled = true
    LOOP
        PERFORM public.send_birthday_notification(
            v_star.star_id,
            'birthday_upcoming'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_profiles_birthday ON public.profiles(birthday) WHERE birthday IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birthday_notifications_star_id ON public.birthday_notifications(star_id);
CREATE INDEX IF NOT EXISTS idx_birthday_notifications_user_id ON public.birthday_notifications(notified_user_id);
CREATE INDEX IF NOT EXISTS idx_birthday_notification_settings_user_star ON public.birthday_notification_settings(user_id, star_id);