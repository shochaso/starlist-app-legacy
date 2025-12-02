-- スター認証システム最終版（事務所・未成年者対応）
-- 作成日: 2025-01-03

-- 1. 認証ステータス最終版の更新
DO $$ 
BEGIN
    -- verification_status_final に事務所対応ステータスを追加
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status_final') THEN
        CREATE TYPE verification_status_final AS ENUM (
            'new_user',                      -- 新規ユーザー
            'awaiting_terms_agreement',     -- 事務所規約同意待ち
            'awaiting_ekyc',                -- eKYC実施待ち
            'ekyc_completed',               -- eKYC完了
            'awaiting_parental_consent',    -- 親権者同意待ち（未成年者用）
            'parental_consent_submitted',   -- 親権者同意書提出済み
            'parental_ekyc_required',       -- 親権者eKYC必要
            'parental_ekyc_completed',      -- 親権者eKYC完了
            'awaiting_sns_verification',    -- SNS所有権確認待ち
            'sns_verification_completed',   -- SNS認証完了
            'pending_review',               -- 運営レビュー待ち
            'approved',                     -- 承認済み
            'rejected',                     -- 拒否
            'suspended'                     -- 停止
        );
    END IF;
END $$;

-- 2. プロフィールテーブルの最終更新（usersはビューなので、profilesテーブルに追加）
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS verification_status_final verification_status_final DEFAULT 'new_user';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS agency_terms_agreed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS agency_terms_agreed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS agency_name VARCHAR(255);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS agency_contact_info TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS final_approval_notes TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

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
  verification_status_final,
  agency_terms_agreed,
  agency_terms_agreed_at,
  agency_name,
  agency_contact_info,
  final_approval_notes,
  approved_by,
  approved_at,
  created_at,
  updated_at
FROM public.profiles;

-- 3. 事務所利用規約同意テーブル
CREATE TABLE IF NOT EXISTS agency_terms_agreements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    agency_name VARCHAR(255),
    agency_contact_email VARCHAR(255),
    agency_contact_phone VARCHAR(50),
    individual_responsibility_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    platform_terms_version VARCHAR(50) NOT NULL,
    agreement_ip_address INET,
    agreement_user_agent TEXT,
    agreed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id) -- 1ユーザー1同意記録
);

-- 4. 統合認証進捗管理テーブル
CREATE TABLE IF NOT EXISTS verification_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- 進捗状況
    terms_agreement_completed BOOLEAN DEFAULT FALSE,
    terms_agreement_completed_at TIMESTAMP WITH TIME ZONE,
    
    ekyc_completed BOOLEAN DEFAULT FALSE,
    ekyc_completed_at TIMESTAMP WITH TIME ZONE,
    ekyc_provider VARCHAR(50),
    ekyc_verification_id VARCHAR(255),
    
    parental_consent_required BOOLEAN DEFAULT FALSE,
    parental_consent_completed BOOLEAN DEFAULT FALSE,
    parental_consent_completed_at TIMESTAMP WITH TIME ZONE,
    parental_consent_id UUID REFERENCES parental_consents(id),
    
    sns_verification_completed BOOLEAN DEFAULT FALSE,
    sns_verification_completed_at TIMESTAMP WITH TIME ZONE,
    sns_verification_count INTEGER DEFAULT 0,
    
    -- 最終ステータス
    all_requirements_met BOOLEAN DEFAULT FALSE,
    submitted_for_review BOOLEAN DEFAULT FALSE,
    submitted_for_review_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- 5. 管理者審査統合ログテーブル
CREATE TABLE IF NOT EXISTS admin_verification_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    
    -- 審査項目チェックリスト
    terms_agreement_checked BOOLEAN DEFAULT FALSE,
    ekyc_identity_verified BOOLEAN DEFAULT FALSE,
    age_verification_completed BOOLEAN DEFAULT FALSE,
    parental_consent_verified BOOLEAN DEFAULT FALSE, -- 未成年者のみ
    sns_ownership_verified BOOLEAN DEFAULT FALSE,
    
    -- 審査結果
    review_decision VARCHAR(50) NOT NULL, -- 'approved', 'rejected', 'request_additional_info'
    review_notes TEXT,
    rejection_reason TEXT,
    additional_requirements TEXT,
    
    -- メタデータ
    review_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    review_completed_at TIMESTAMP WITH TIME ZONE,
    review_duration_minutes INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. インデックス作成
CREATE INDEX IF NOT EXISTS idx_profiles_verification_status_final ON public.profiles(verification_status_final);
CREATE INDEX IF NOT EXISTS idx_profiles_agency_terms_agreed ON public.profiles(agency_terms_agreed);
CREATE INDEX IF NOT EXISTS idx_agency_terms_agreements_user_id ON agency_terms_agreements(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_progress_user_id ON verification_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_progress_all_requirements_met ON verification_progress(all_requirements_met);
CREATE INDEX IF NOT EXISTS idx_admin_verification_reviews_user_id ON admin_verification_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_verification_reviews_decision ON admin_verification_reviews(review_decision);

-- 7. RLS (Row Level Security) ポリシー設定

-- agency_terms_agreements のポリシー
ALTER TABLE agency_terms_agreements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分の事務所規約同意を管理可能" ON agency_terms_agreements
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "管理者は全ての事務所規約同意を閲覧可能" ON agency_terms_agreements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- verification_progress のポリシー
ALTER TABLE verification_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分の認証進捗を閲覧可能" ON verification_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "管理者は全ての認証進捗を閲覧可能" ON verification_progress
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- admin_verification_reviews のポリシー
ALTER TABLE admin_verification_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理者のみ審査レビューを管理可能" ON admin_verification_reviews
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 8. 関数: 認証進捗の自動更新
CREATE OR REPLACE FUNCTION update_verification_progress()
RETURNS TRIGGER AS $$
DECLARE
    progress_record verification_progress%ROWTYPE;
    all_requirements_met_flag BOOLEAN := FALSE;
BEGIN
    -- 認証進捗レコードを取得または作成
    SELECT * INTO progress_record 
    FROM verification_progress 
    WHERE user_id = NEW.id;
    
    IF progress_record IS NULL THEN
        INSERT INTO verification_progress (user_id) 
        VALUES (NEW.id) 
        RETURNING * INTO progress_record;
    END IF;

    -- 各要件の完了状況をチェック
    -- 事務所規約同意
    IF NEW.agency_terms_agreed = TRUE AND progress_record.terms_agreement_completed = FALSE THEN
        UPDATE verification_progress 
        SET 
            terms_agreement_completed = TRUE,
            terms_agreement_completed_at = NOW(),
            updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;

    -- eKYC完了
    IF NEW.ekyc_verified_at IS NOT NULL AND progress_record.ekyc_completed = FALSE THEN
        UPDATE verification_progress 
        SET 
            ekyc_completed = TRUE,
            ekyc_completed_at = NEW.ekyc_verified_at,
            ekyc_provider = NEW.ekyc_provider,
            ekyc_verification_id = NEW.ekyc_verification_id,
            updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;

    -- 親権者同意要件設定
    IF NEW.is_minor = TRUE AND progress_record.parental_consent_required = FALSE THEN
        UPDATE verification_progress 
        SET 
            parental_consent_required = TRUE,
            updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;

    -- 全要件完了チェック
    SELECT 
        terms_agreement_completed AND
        ekyc_completed AND
        (NOT parental_consent_required OR parental_consent_completed) AND
        sns_verification_completed
    INTO all_requirements_met_flag
    FROM verification_progress 
    WHERE user_id = NEW.id;

    -- 全要件完了時の処理
    IF all_requirements_met_flag = TRUE THEN
        UPDATE verification_progress 
        SET 
            all_requirements_met = TRUE,
            updated_at = NOW()
        WHERE user_id = NEW.id;
        
        -- ユーザーステータスを審査待ちに更新
        NEW.verification_status_final := 'pending_review';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガー作成
DROP TRIGGER IF EXISTS trigger_update_verification_progress ON users;
CREATE TRIGGER trigger_update_verification_progress
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_verification_progress();

-- 9. 関数: 管理者審査完了処理
CREATE OR REPLACE FUNCTION complete_admin_review(
    p_user_id UUID,
    p_admin_user_id UUID,
    p_decision VARCHAR(50),
    p_review_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    review_id UUID;
BEGIN
    -- 審査レビュー記録を作成
    INSERT INTO admin_verification_reviews (
        user_id,
        admin_user_id,
        review_decision,
        review_notes,
        review_completed_at,
        terms_agreement_checked,
        ekyc_identity_verified,
        age_verification_completed,
        parental_consent_verified,
        sns_ownership_verified
    )
    SELECT 
        p_user_id,
        p_admin_user_id,
        p_decision,
        p_review_notes,
        NOW(),
        vp.terms_agreement_completed,
        vp.ekyc_completed,
        vp.ekyc_completed,
        COALESCE(vp.parental_consent_completed, NOT vp.parental_consent_required),
        vp.sns_verification_completed
    FROM verification_progress vp
    WHERE vp.user_id = p_user_id
    RETURNING id INTO review_id;

    -- ユーザーステータスを更新
    IF p_decision = 'approved' THEN
        UPDATE users 
        SET 
            verification_status_final = 'approved',
            approved_by = p_admin_user_id,
            approved_at = NOW(),
            final_approval_notes = p_review_notes,
            updated_at = NOW()
        WHERE id = p_user_id;
    ELSIF p_decision = 'rejected' THEN
        UPDATE users 
        SET 
            verification_status_final = 'rejected',
            verification_notes = p_review_notes,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 10. ビュー: 管理者用統合審査ビュー
CREATE OR REPLACE VIEW admin_verification_dashboard AS
SELECT 
    u.id as user_id,
    u.full_name as name,
    u.email,
    u.legal_name,
    u.birth_date,
    u.is_minor,
    u.verification_status_final,
    u.created_at as registration_date,
    
    -- 事務所規約
    ata.agency_name,
    ata.agreed_at as terms_agreed_at,
    
    -- 認証進捗
    vp.terms_agreement_completed,
    vp.ekyc_completed,
    vp.ekyc_provider,
    vp.parental_consent_required,
    vp.parental_consent_completed,
    vp.sns_verification_completed,
    vp.sns_verification_count,
    vp.all_requirements_met,
    
    -- 親権者同意（未成年者のみ）
    pc.parent_full_name,
    pc.parent_email,
    pc.consent_document_url,
    pc.verification_status as parental_consent_status,
    
    -- SNS認証
    (SELECT COUNT(*) FROM sns_verifications sv WHERE sv.user_id = u.id AND sv.ownership_verified = TRUE) as verified_sns_count,
    (SELECT json_agg(json_build_object('platform', sv.platform, 'handle', sv.account_handle, 'followers', sv.follower_count)) 
     FROM sns_verifications sv WHERE sv.user_id = u.id AND sv.ownership_verified = TRUE) as sns_accounts,
    
    -- 最新審査レビュー
    avr.review_decision as last_review_decision,
    avr.review_notes as last_review_notes,
    avr.review_completed_at as last_review_date
    
FROM public.profiles u
LEFT JOIN agency_terms_agreements ata ON u.id = ata.user_id
LEFT JOIN verification_progress vp ON u.id = vp.user_id
LEFT JOIN parental_consents pc ON u.id = pc.user_id
LEFT JOIN LATERAL (
    SELECT * FROM admin_verification_reviews 
    WHERE user_id = u.id 
    ORDER BY created_at DESC 
    LIMIT 1
) avr ON TRUE
WHERE u.role = 'star' OR u.verification_status_final IS NOT NULL;

-- コメント追加
COMMENT ON TABLE agency_terms_agreements IS '事務所利用規約同意記録';
COMMENT ON TABLE verification_progress IS '統合認証進捗管理';
COMMENT ON TABLE admin_verification_reviews IS '管理者審査統合ログ';
COMMENT ON VIEW admin_verification_dashboard IS '管理者用統合審査ダッシュボード';
COMMENT ON FUNCTION update_verification_progress() IS '認証進捗自動更新';
COMMENT ON FUNCTION complete_admin_review(UUID, UUID, VARCHAR, TEXT) IS '管理者審査完了処理'; 