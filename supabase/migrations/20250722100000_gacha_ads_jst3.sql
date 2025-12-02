-- ============================================================
-- GACHA / ADS JST3 - Final MVP Schema
-- ============================================================

-- ----------------------------------------
-- 1. ad_views（広告視聴ログ）
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS ad_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles (id) ON DELETE CASCADE,
  viewed_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ad_views_unique_per_minute UNIQUE (user_id, viewed_at)
);

-- インデックス
CREATE INDEX IF NOT EXISTS ad_views_user_id_idx ON ad_views (user_id);
CREATE INDEX IF NOT EXISTS ad_views_viewed_at_idx ON ad_views (viewed_at);

-- ----------------------------------------
-- 2. gacha_daily_attempts（1日あたりのガチャ回数）
-- JST+3 = "日本時間の一日区切り"
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS gacha_daily_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles (id) ON DELETE CASCADE,
  date_key char(8) NOT NULL,
  attempts int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, date_key)
);

CREATE INDEX IF NOT EXISTS gacha_attempts_user_id_idx ON gacha_daily_attempts (user_id);
CREATE INDEX IF NOT EXISTS gacha_attempts_date_key_idx ON gacha_daily_attempts (date_key);

-- ----------------------------------------
-- 3. RPC: get_jst3_date_key（日本時間の0時区切り）
-- ----------------------------------------
CREATE OR REPLACE FUNCTION get_jst3_date_key()
RETURNS char(8)
LANGUAGE sql STABLE
AS $$
  SELECT to_char((now() AT TIME ZONE 'Asia/Tokyo'), 'YYYYMMDD')::char(8);
$$;

-- ----------------------------------------
-- 4. RPC: initialize_daily_gacha_attempts_jst3
-- ----------------------------------------
CREATE OR REPLACE FUNCTION initialize_daily_gacha_attempts_jst3(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  d char(8);
BEGIN
  d := get_jst3_date_key();

  INSERT INTO gacha_daily_attempts (user_id, date_key, attempts)
  SELECT target_user_id, d, 0
  WHERE NOT EXISTS (
    SELECT 1 FROM gacha_daily_attempts
    WHERE user_id = target_user_id AND date_key = d
  );
END;
$$;

-- ----------------------------------------
-- 5. RPC: complete_ad_view_and_grant_ticket
-- （広告視聴 → ログ追加 → ガチャ回数+1）
-- ----------------------------------------
CREATE OR REPLACE FUNCTION complete_ad_view_and_grant_ticket(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  d char(8);
BEGIN
  d := get_jst3_date_key();

  -- 広告ログ
  INSERT INTO ad_views (user_id) VALUES (target_user_id);

  -- 日次初期化
  PERFORM initialize_daily_gacha_attempts_jst3(target_user_id);

  -- ガチャ回数+1
  UPDATE gacha_daily_attempts
  SET attempts = attempts + 1,
      updated_at = now()
  WHERE user_id = target_user_id
    AND date_key = d;
END;
$$;

-- ----------------------------------------
-- 6. RPC: consume_gacha_attempt_atomic
-- （ガチャを引く → 回数-1）
-- ----------------------------------------
CREATE OR REPLACE FUNCTION consume_gacha_attempt_atomic(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  d char(8);
  ok boolean := false;
BEGIN
  d := get_jst3_date_key();

  UPDATE gacha_daily_attempts
  SET attempts = attempts - 1,
      updated_at = now()
  WHERE user_id = target_user_id
    AND date_key = d
    AND attempts > 0
  RETURNING true INTO ok;

  RETURN ok;
END;
$$;
