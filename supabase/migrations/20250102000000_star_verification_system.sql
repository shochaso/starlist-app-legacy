-- スター認証システム強化（未成年者対応）
-- 作成日: 2025-01-02

-- 1. 認証ステータス更新（未成年者対応）
DO $$ 
BEGIN
    -- verification_status に未成年者関連ステータスを追加
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status_type') THEN
        CREATE TYPE verification_status_type AS ENUM (
            'pending',                    -- 申請中
            'documents_submitted',        -- 書類提出済み
            'ekyc_in_progress',          -- eKYC実行中
            'ekyc_completed',            -- eKYC完了
            'awaiting_parental_consent', -- 親権者同意待ち（未成年者用）
            'parental_consent_submitted', -- 親権者同意書提出済み
            'parental_ekyc_required',    -- 親権者eKYC必要
            'parental_ekyc_completed',   -- 親権者eKYC完了
            'sns_verification_pending',   -- SNS認証待ち
            'sns_verification_completed', -- SNS認証完了
            'under_review',              -- 運営審査中
            'approved',                  -- 承認済み
            'rejected',                  -- 拒否
            'suspended'                  -- 停止
        );
    END IF;
END $$;

-- 2. プロフィールテーブルの拡張（usersはビューなので、profilesテーブルに追加）
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS verification_status verification_status_type DEFAULT 'pending';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_minor BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ekyc_provider VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ekyc_verification_id VARCHAR(255);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ekyc_verified_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS legal_name VARCHAR(255);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS verification_notes TEXT;

-- usersビューを更新して新しいカラムを含める（既存の列順序を維持）
DROP VIEW IF EXISTS public.users;
CREATE VIEW public.users AS
SELECT 
  id,
  username,
  full_name,
  avatar_url,
  bio,
  website,
  location,
  email,
  phone,
  role,
  status,
  is_verified,
  verification_badges,
  last_login_at,
  verification_status,
  birth_date,
  is_minor,
  ekyc_provider,
  ekyc_verification_id,
  ekyc_verified_at,
  legal_name,
  verification_notes,
  created_at,
  updated_at
FROM public.profiles;

-- 3. 親権者同意テーブル
CREATE TABLE IF NOT EXISTS parental_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    parent_full_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255),
    parent_phone VARCHAR(50),
    parent_address TEXT,
    relationship_to_minor VARCHAR(100) NOT NULL, -- 父、母、後見人など
    consent_document_url TEXT, -- 同意書のファイルURL
    consent_submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    parent_ekyc_provider VARCHAR(50),
    parent_ekyc_verification_id VARCHAR(255),
    parent_ekyc_verified_at TIMESTAMP WITH TIME ZONE,
    parent_legal_name VARCHAR(255),
    verification_status verification_status_type DEFAULT 'parental_consent_submitted',
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. eKYC認証ログテーブル
CREATE TABLE IF NOT EXISTS ekyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    parental_consent_id UUID REFERENCES parental_consents(id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL, -- 'user' or 'parent'
    provider VARCHAR(50) NOT NULL, -- 'trustdock', 'liquid', etc.
    provider_verification_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'pending', 'success', 'failed'
    result_data JSONB, -- eKYCサービスからの結果データ
    verified_name VARCHAR(255),
    verified_birth_date DATE,
    verified_address TEXT,
    verification_score DECIMAL(3,2), -- 信頼度スコア (0.00-1.00)
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- どちらかのIDが必須
    CONSTRAINT ekyc_user_or_parent CHECK (
        (user_id IS NOT NULL AND parental_consent_id IS NULL) OR
        (user_id IS NULL AND parental_consent_id IS NOT NULL)
    )
);

-- 5. SNS連携・認証テーブル
CREATE TABLE IF NOT EXISTS sns_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL, -- 'youtube', 'instagram', 'tiktok', 'twitter'
    account_handle VARCHAR(255) NOT NULL, -- @username
    account_url TEXT NOT NULL,
    follower_count INTEGER,
    verification_code VARCHAR(100) NOT NULL, -- プロフィールに埋め込むコード
    ownership_verified BOOLEAN DEFAULT FALSE,
    ownership_verified_at TIMESTAMP WITH TIME ZONE,
    api_data JSONB, -- SNS APIから取得したデータ
    verification_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'verified', 'failed'
    verification_attempts INTEGER DEFAULT 0,
    last_verification_attempt TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 同一ユーザーの同一プラットフォームは1つまで
    UNIQUE(user_id, platform)
);

-- 6. 管理者審査ログテーブル
CREATE TABLE IF NOT EXISTS admin_review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    review_type VARCHAR(50) NOT NULL, -- 'initial_review', 'parental_consent_review', 'appeal_review'
    previous_status verification_status_type,
    new_status verification_status_type NOT NULL,
    decision VARCHAR(50) NOT NULL, -- 'approved', 'rejected', 'request_additional_info'
    review_notes TEXT,
    reviewed_documents JSONB, -- 確認した書類のリスト
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. インデックス作成
CREATE INDEX IF NOT EXISTS idx_profiles_verification_status ON public.profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_is_minor ON public.profiles(is_minor);
CREATE INDEX IF NOT EXISTS idx_parental_consents_user_id ON parental_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_parental_consents_status ON parental_consents(verification_status);
CREATE INDEX IF NOT EXISTS idx_ekyc_verifications_user_id ON ekyc_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_ekyc_verifications_parental_consent_id ON ekyc_verifications(parental_consent_id);
CREATE INDEX IF NOT EXISTS idx_sns_verifications_user_id ON sns_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_sns_verifications_platform ON sns_verifications(platform);
CREATE INDEX IF NOT EXISTS idx_admin_review_logs_user_id ON admin_review_logs(user_id);

-- 8. RLS (Row Level Security) ポリシー設定

-- parental_consents のポリシー
ALTER TABLE parental_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分の親権者同意情報を管理可能" ON parental_consents
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "管理者は全ての親権者同意情報を閲覧可能" ON parental_consents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- ekyc_verifications のポリシー
ALTER TABLE ekyc_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のeKYC情報を閲覧可能" ON ekyc_verifications
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM parental_consents pc
      WHERE pc.id = parental_consent_id 
      AND pc.user_id = auth.uid()
    )
  );

CREATE POLICY "管理者は全てのeKYC情報を閲覧可能" ON ekyc_verifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- sns_verifications のポリシー
ALTER TABLE sns_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のSNS認証情報を管理可能" ON sns_verifications
  FOR ALL USING (auth.uid() = user_id);

-- admin_review_logs のポリシー
ALTER TABLE admin_review_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理者のみ審査ログを閲覧可能" ON admin_review_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 9. 関数: 年齢計算と未成年者フラグ更新
CREATE OR REPLACE FUNCTION update_minor_status()
RETURNS TRIGGER AS $$
BEGIN
    -- 生年月日が設定されている場合、年齢を計算して未成年者フラグを更新
    IF NEW.birth_date IS NOT NULL THEN
        NEW.is_minor := (EXTRACT(YEAR FROM AGE(NEW.birth_date)) < 18);
        
        -- 未成年者の場合、認証ステータスを親権者同意待ちに変更
        IF NEW.is_minor = TRUE AND NEW.verification_status = 'ekyc_completed' THEN
            NEW.verification_status := 'awaiting_parental_consent';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガー作成
DROP TRIGGER IF EXISTS trigger_update_minor_status ON public.profiles;
CREATE TRIGGER trigger_update_minor_status
    BEFORE INSERT OR UPDATE OF birth_date
    ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_minor_status();

-- 10. 関数: 認証完了チェック
CREATE OR REPLACE FUNCTION check_verification_completion(p_user_id UUID)
RETURNS verification_status_type AS $$
DECLARE
    v_user users%ROWTYPE;
    v_has_parental_consent BOOLEAN := FALSE;
    v_has_sns_verification BOOLEAN := FALSE;
BEGIN
    -- ユーザー情報取得
    SELECT * INTO v_user FROM public.profiles WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN 'pending';
    END IF;
    
    -- 未成年者の場合、親権者同意をチェック
    IF v_user.is_minor = TRUE THEN
        SELECT EXISTS(
            SELECT 1 FROM parental_consents 
            WHERE user_id = p_user_id 
            AND verification_status = 'parental_ekyc_completed'
        ) INTO v_has_parental_consent;
        
        IF NOT v_has_parental_consent THEN
            RETURN v_user.verification_status;
        END IF;
    END IF;
    
    -- SNS認証をチェック
    SELECT EXISTS(
        SELECT 1 FROM sns_verifications 
        WHERE user_id = p_user_id 
        AND ownership_verified = TRUE
    ) INTO v_has_sns_verification;
    
    -- 全ての条件が満たされているかチェック
    IF v_user.verification_status = 'ekyc_completed' 
       AND (v_user.is_minor = FALSE OR v_has_parental_consent = TRUE)
       AND v_has_sns_verification = TRUE THEN
        RETURN 'under_review';
    END IF;
    
    RETURN v_user.verification_status;
END;
$$ LANGUAGE plpgsql;

-- コメント追加
COMMENT ON TABLE parental_consents IS '未成年者の親権者同意情報';
COMMENT ON TABLE ekyc_verifications IS 'eKYC認証ログ（本人・親権者両対応）';
COMMENT ON TABLE sns_verifications IS 'SNSアカウント連携・所有権確認';
COMMENT ON TABLE admin_review_logs IS '管理者による審査履歴';
COMMENT ON FUNCTION update_minor_status() IS '生年月日から未成年者判定と認証ステータス更新';
COMMENT ON FUNCTION check_verification_completion(UUID) IS '認証完了状況チェック'; 