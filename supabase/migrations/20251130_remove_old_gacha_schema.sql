-- ============================================================
-- 古いガチャスキーマの削除
-- ============================================================
-- このマイグレーションは、古いgacha_attemptsテーブルと
-- 関連するRPC関数を削除します。
-- 新しいスキーマ（gacha_daily_attempts）に移行済みのため、
-- 古いスキーマは不要になりました。

-- ============================================================
-- 1. 古いRPC関数の削除（存在する場合のみ）
-- ============================================================

-- get_available_gacha_attempts（存在しない場合はエラーを無視）
DROP FUNCTION IF EXISTS get_available_gacha_attempts(uuid);

-- add_gacha_bonus_attempts（存在しない場合はエラーを無視）
DROP FUNCTION IF EXISTS add_gacha_bonus_attempts(uuid, int);

-- ============================================================
-- 2. 古いテーブルの削除（存在する場合のみ）
-- ============================================================

-- 注意: 実際の削除前に、データの移行が必要な場合は
-- 別途マイグレーションでデータを移行してください

-- gacha_attemptsテーブルが存在する場合のみ削除
-- 注意: このテーブルが存在しない場合はエラーを無視
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'gacha_attempts'
  ) THEN
    -- 外部キー制約がある場合は先に削除
    ALTER TABLE IF EXISTS gacha_attempts 
      DROP CONSTRAINT IF EXISTS gacha_attempts_user_id_fkey;
    
    -- テーブルを削除
    DROP TABLE IF EXISTS gacha_attempts;
    
    RAISE NOTICE 'gacha_attemptsテーブルを削除しました';
  ELSE
    RAISE NOTICE 'gacha_attemptsテーブルは存在しません（スキップ）';
  END IF;
END $$;

-- ============================================================
-- 3. インデックスの削除（存在する場合のみ）
-- ============================================================

DROP INDEX IF EXISTS gacha_attempts_user_id_idx;
DROP INDEX IF EXISTS gacha_attempts_date_idx;

-- ============================================================
-- 4. 確認メッセージ
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '古いガチャスキーマの削除が完了しました';
  RAISE NOTICE '新しいスキーマ（gacha_daily_attempts）を使用してください';
END $$;


