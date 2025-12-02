-- プレミアム質問システムのためのテーブル追加
-- 作成日: 2025-06-22

-- プレミアム質問テーブル
CREATE TABLE IF NOT EXISTS public.premium_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    questioner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    question_cost INTEGER NOT NULL CHECK (question_cost > 0),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '3 days'),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'answered', 'expired', 'refunded')),
    star_answer TEXT, -- 'A', 'B', または null
    answer_explanation TEXT,
    answered_at TIMESTAMP WITH TIME ZONE,
    is_public BOOLEAN DEFAULT false,
    s_points_spent INTEGER NOT NULL,
    s_points_refunded INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- プレミアム質問料金設定テーブル
CREATE TABLE IF NOT EXISTS public.premium_question_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    star_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    base_price INTEGER NOT NULL DEFAULT 100 CHECK (base_price > 0),
    priority_multiplier DECIMAL(3,2) DEFAULT 1.0 CHECK (priority_multiplier >= 1.0),
    max_questions_per_day INTEGER DEFAULT 5 CHECK (max_questions_per_day > 0),
    is_accepting_questions BOOLEAN DEFAULT TRUE,
    auto_answer_enabled BOOLEAN DEFAULT FALSE,
    response_time_hours INTEGER DEFAULT 72 CHECK (response_time_hours > 0),
    refund_policy TEXT DEFAULT 'auto_refund_after_expiry',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(star_id)
);

-- プレミアム質問通知テーブル
CREATE TABLE IF NOT EXISTS public.premium_question_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.premium_questions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('question_received', 'answer_posted', 'expiry_warning', 'refund_processed')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLSポリシーの設定
ALTER TABLE public.premium_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.premium_question_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.premium_question_notifications ENABLE ROW LEVEL SECURITY;

-- プレミアム質問のポリシー
CREATE POLICY "質問者は自分の質問を閲覧可能" ON public.premium_questions
    FOR SELECT USING (auth.uid() = questioner_id);

CREATE POLICY "スターは自分への質問を管理可能" ON public.premium_questions
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "公開質問は誰でも閲覧可能" ON public.premium_questions
    FOR SELECT USING (is_public = true AND status = 'answered');

-- プレミアム質問料金設定のポリシー
CREATE POLICY "スターは自分の料金設定を管理可能" ON public.premium_question_pricing
    FOR ALL USING (auth.uid() = star_id);

CREATE POLICY "料金設定は誰でも閲覧可能" ON public.premium_question_pricing
    FOR SELECT USING (true);

-- プレミアム質問通知のポリシー
CREATE POLICY "ユーザーは自分の通知を閲覧可能" ON public.premium_question_notifications
    FOR SELECT USING (auth.uid() = user_id);

-- プレミアム質問を作成する関数
CREATE OR REPLACE FUNCTION public.create_premium_question(
    p_questioner_id UUID,
    p_star_id UUID,
    p_question_text TEXT,
    p_option_a TEXT,
    p_option_b TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_pricing RECORD;
    v_question_cost INTEGER;
    v_user_balance INTEGER;
    v_daily_questions INTEGER;
    v_question_id UUID;
BEGIN
    -- 認証チェック
    IF auth.uid() != p_questioner_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- スターの料金設定を取得
    SELECT * INTO v_pricing
    FROM public.premium_question_pricing
    WHERE star_id = p_star_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Star not accepting premium questions');
    END IF;

    -- スターが質問を受け付けているかチェック
    IF NOT v_pricing.is_accepting_questions THEN
        RETURN jsonb_build_object('success', false, 'error', 'Star not currently accepting questions');
    END IF;

    -- 質問コストを計算
    v_question_cost := v_pricing.base_price;

    -- ユーザーのSポイント残高をチェック
    SELECT balance INTO v_user_balance
    FROM public.s_points
    WHERE user_id = p_questioner_id;

    IF v_user_balance < v_question_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient S-points');
    END IF;

    -- 本日の質問数をチェック
    SELECT COUNT(*) INTO v_daily_questions
    FROM public.premium_questions
    WHERE questioner_id = p_questioner_id
    AND star_id = p_star_id
    AND created_at >= CURRENT_DATE;

    IF v_daily_questions >= v_pricing.max_questions_per_day THEN
        RETURN jsonb_build_object('success', false, 'error', 'Daily question limit exceeded');
    END IF;

    -- プレミアム質問を作成
    INSERT INTO public.premium_questions (
        questioner_id,
        star_id,
        question_text,
        option_a,
        option_b,
        question_cost,
        expires_at,
        s_points_spent
    ) VALUES (
        p_questioner_id,
        p_star_id,
        p_question_text,
        p_option_a,
        p_option_b,
        v_question_cost,
        NOW() + INTERVAL '1 hour' * v_pricing.response_time_hours,
        v_question_cost
    ) RETURNING id INTO v_question_id;

    -- Sポイントを消費
    UPDATE public.s_points
    SET balance = balance - v_question_cost,
        total_spent = total_spent + v_question_cost,
        updated_at = NOW()
    WHERE user_id = p_questioner_id;

    -- Sポイント取引履歴を記録
    INSERT INTO public.s_point_transactions (
        user_id,
        amount,
        transaction_type,
        source_type,
        source_id,
        description
    ) VALUES (
        p_questioner_id,
        -v_question_cost,
        'spent',
        'premium_question',
        v_question_id,
        'プレミアム質問を送信'
    );

    -- スターに通知
    INSERT INTO public.premium_question_notifications (
        question_id,
        user_id,
        notification_type,
        message
    ) VALUES (
        v_question_id,
        p_star_id,
        'question_received',
        'プレミアム質問が届きました'
    );

    -- 通常の通知テーブルにも追加
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        data
    ) VALUES (
        p_star_id,
        'premium_question',
        'プレミアム質問',
        'プレミアム質問が届きました。3日以内に回答してください。',
        jsonb_build_object('question_id', v_question_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'question_id', v_question_id,
        'cost', v_question_cost,
        'expires_at', NOW() + INTERVAL '1 hour' * v_pricing.response_time_hours
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- プレミアム質問に回答する関数
CREATE OR REPLACE FUNCTION public.answer_premium_question(
    p_question_id UUID,
    p_star_answer TEXT,
    p_explanation TEXT DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
    v_question RECORD;
    v_questioner_id UUID;
BEGIN
    -- 質問情報を取得
    SELECT * INTO v_question
    FROM public.premium_questions
    WHERE id = p_question_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Question not found');
    END IF;

    -- 認証チェック（スターのみ回答可能）
    IF auth.uid() != v_question.star_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 質問の状態チェック
    IF v_question.status != 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Question already answered or expired');
    END IF;

    -- 期限チェック
    IF v_question.expires_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Question has expired');
    END IF;

    -- 回答の妥当性チェック
    IF p_star_answer NOT IN ('A', 'B') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid answer option');
    END IF;

    -- 質問を更新
    UPDATE public.premium_questions
    SET star_answer = p_star_answer,
        answer_explanation = p_explanation,
        answered_at = NOW(),
        status = 'answered',
        is_public = p_is_public,
        updated_at = NOW()
    WHERE id = p_question_id;

    -- 質問者に通知
    INSERT INTO public.premium_question_notifications (
        question_id,
        user_id,
        notification_type,
        message
    ) VALUES (
        p_question_id,
        v_question.questioner_id,
        'answer_posted',
        'プレミアム質問に回答がありました'
    );

    -- 通常の通知テーブルにも追加
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        data
    ) VALUES (
        v_question.questioner_id,
        'premium_question_answered',
        '質問に回答',
        'あなたのプレミアム質問に回答がありました！',
        jsonb_build_object('question_id', p_question_id)
    );

    RETURN jsonb_build_object('success', true, 'message', 'Question answered successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 期限切れ質問の自動返金処理関数
CREATE OR REPLACE FUNCTION public.process_expired_premium_questions()
RETURNS JSONB AS $$
DECLARE
    v_question RECORD;
    v_refund_count INTEGER := 0;
BEGIN
    -- 期限切れでまだ未処理の質問を取得
    FOR v_question IN 
        SELECT id, questioner_id, s_points_spent
        FROM public.premium_questions
        WHERE status = 'pending'
        AND expires_at < NOW()
    LOOP
        -- 質問を期限切れに更新
        UPDATE public.premium_questions
        SET status = 'expired',
            updated_at = NOW()
        WHERE id = v_question.id;

        -- Sポイントを返金
        UPDATE public.s_points
        SET balance = balance + v_question.s_points_spent,
            updated_at = NOW()
        WHERE user_id = v_question.questioner_id;

        -- 返金履歴を記録
        INSERT INTO public.s_point_transactions (
            user_id,
            amount,
            transaction_type,
            source_type,
            source_id,
            description
        ) VALUES (
            v_question.questioner_id,
            v_question.s_points_spent,
            'refund',
            'premium_question',
            v_question.id,
            'プレミアム質問期限切れによる返金'
        );

        -- 返金額を記録
        UPDATE public.premium_questions
        SET s_points_refunded = v_question.s_points_spent
        WHERE id = v_question.id;

        -- 通知
        INSERT INTO public.premium_question_notifications (
            question_id,
            user_id,
            notification_type,
            message
        ) VALUES (
            v_question.id,
            v_question.questioner_id,
            'refund_processed',
            'プレミアム質問の期限切れにより、Sポイントが返金されました'
        );

        -- 通常の通知テーブルにも追加
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            data
        ) VALUES (
            v_question.questioner_id,
            'premium_question_refund',
            'Sポイント返金',
            format('プレミアム質問の期限切れにより、%s SPが返金されました。', v_question.s_points_spent),
            jsonb_build_object('question_id', v_question.id, 'refund_amount', v_question.s_points_spent)
        );

        v_refund_count := v_refund_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'refunded_questions', v_refund_count
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- プレミアム質問料金設定を更新する関数
CREATE OR REPLACE FUNCTION public.update_premium_question_pricing(
    p_star_id UUID,
    p_base_price INTEGER,
    p_max_questions_per_day INTEGER,
    p_is_accepting_questions BOOLEAN,
    p_response_time_hours INTEGER
)
RETURNS JSONB AS $$
BEGIN
    -- 認証チェック
    IF auth.uid() != p_star_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 設定を更新または作成
    INSERT INTO public.premium_question_pricing (
        star_id,
        base_price,
        max_questions_per_day,
        is_accepting_questions,
        response_time_hours,
        updated_at
    ) VALUES (
        p_star_id,
        p_base_price,
        p_max_questions_per_day,
        p_is_accepting_questions,
        p_response_time_hours,
        NOW()
    )
    ON CONFLICT (star_id)
    DO UPDATE SET
        base_price = EXCLUDED.base_price,
        max_questions_per_day = EXCLUDED.max_questions_per_day,
        is_accepting_questions = EXCLUDED.is_accepting_questions,
        response_time_hours = EXCLUDED.response_time_hours,
        updated_at = NOW();

    RETURN jsonb_build_object('success', true, 'message', 'Pricing updated successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 期限が近い質問の警告通知を送信する関数
CREATE OR REPLACE FUNCTION public.send_expiry_warnings()
RETURNS VOID AS $$
DECLARE
    v_question RECORD;
BEGIN
    -- 期限まで12時間以内の未回答質問を取得
    FOR v_question IN 
        SELECT id, star_id, questioner_id, expires_at
        FROM public.premium_questions
        WHERE status = 'pending'
        AND expires_at > NOW()
        AND expires_at <= NOW() + INTERVAL '12 hours'
        AND NOT EXISTS (
            SELECT 1 FROM public.premium_question_notifications
            WHERE question_id = public.premium_questions.id
            AND notification_type = 'expiry_warning'
            AND sent_at > NOW() - INTERVAL '24 hours'
        )
    LOOP
        -- スターに警告通知
        INSERT INTO public.premium_question_notifications (
            question_id,
            user_id,
            notification_type,
            message
        ) VALUES (
            v_question.id,
            v_question.star_id,
            'expiry_warning',
            'プレミアム質問の期限が12時間以内に迫っています'
        );

        -- 通常の通知テーブルにも追加
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            data
        ) VALUES (
            v_question.star_id,
            'premium_question_warning',
            '回答期限警告',
            'プレミアム質問の回答期限が12時間以内に迫っています。',
            jsonb_build_object('question_id', v_question.id, 'expires_at', v_question.expires_at)
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_premium_questions_star_id ON public.premium_questions(star_id);
CREATE INDEX IF NOT EXISTS idx_premium_questions_questioner_id ON public.premium_questions(questioner_id);
CREATE INDEX IF NOT EXISTS idx_premium_questions_status ON public.premium_questions(status);
CREATE INDEX IF NOT EXISTS idx_premium_questions_expires_at ON public.premium_questions(expires_at);
CREATE INDEX IF NOT EXISTS idx_premium_question_notifications_user_id ON public.premium_question_notifications(user_id);

-- 期限切れ質問の自動処理のためのcron jobを設定（Supabase Edge Functionsで実行される想定）
-- SELECT cron.schedule('process-expired-premium-questions', '0 */6 * * *', 'SELECT public.process_expired_premium_questions();');
-- SELECT cron.schedule('send-expiry-warnings', '0 */2 * * *', 'SELECT public.send_expiry_warnings();');