-- タグ付けのみ経路サポート：最小DB拡張
-- 既存 public.contents テーブルに列追加のみ（別テーブル不要）

-- contentsテーブルが存在しない場合は作成
CREATE TABLE IF NOT EXISTS public.contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
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

-- 1) ingestモード / 信頼度 / タグ配列 / 発生日
ALTER TABLE public.contents
  ADD COLUMN IF NOT EXISTS ingest_mode TEXT DEFAULT 'full' CHECK (ingest_mode IN ('full','tag_only')),
  ADD COLUMN IF NOT EXISTS confidence  NUMERIC(3,2) CHECK (confidence >= 0 AND confidence <= 1),
  ADD COLUMN IF NOT EXISTS tags        TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS occurred_at TIMESTAMPTZ;

-- 2) カテゴリ / サービス / ブランド・店舗（検索用）
ALTER TABLE public.contents
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS service  TEXT,
  ADD COLUMN IF NOT EXISTS brand_or_store TEXT;

-- 3) 一元検索ビュー（既存UIのクエリ先をこれに差し替え）
CREATE OR REPLACE VIEW public.search_index AS
SELECT
  id, 
  author_id, 
  title, 
  description, 
  type, 
  url, 
  metadata,
  ingest_mode, 
  confidence, 
  tags, 
  occurred_at,
  category, 
  service, 
  brand_or_store,
  created_at, 
  updated_at,
  is_published,
  -- 全文検索用ベクトル（日本語対応）
  to_tsvector('simple',
    coalesce(title,'') || ' ' ||
    coalesce(description,'') || ' ' ||
    coalesce(category,'') || ' ' ||
    coalesce(service,'') || ' ' ||
    coalesce(brand_or_store,'') || ' ' ||
    array_to_string(tags,' ')
  ) AS search_vector
FROM public.contents
WHERE is_published = TRUE;

-- 4) インデックス作成
CREATE INDEX IF NOT EXISTS idx_contents_ingest_mode ON public.contents(ingest_mode);
CREATE INDEX IF NOT EXISTS idx_contents_category_service ON public.contents(category, service);
CREATE INDEX IF NOT EXISTS idx_contents_tags ON public.contents USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_contents_occurred_at ON public.contents(occurred_at DESC);
-- 全文検索インデックス（IMMUTABLE制約のため、個別カラムのインデックスのみ作成）
CREATE INDEX IF NOT EXISTS idx_contents_title_tsvector ON public.contents USING GIN(to_tsvector('simple', coalesce(title,'')));
CREATE INDEX IF NOT EXISTS idx_contents_description_tsvector ON public.contents USING GIN(to_tsvector('simple', coalesce(description,'')));
CREATE INDEX IF NOT EXISTS idx_contents_tags_gin ON public.contents USING GIN(tags);

-- 5) コメント追加（ドキュメント）
COMMENT ON COLUMN public.contents.ingest_mode IS '取り込みモード: full=完全処理, tag_only=タグのみ';
COMMENT ON COLUMN public.contents.confidence IS 'マッチング信頼度（0.0〜1.0）';
COMMENT ON COLUMN public.contents.tags IS '検索用タグ配列（最大64個推奨）';
COMMENT ON COLUMN public.contents.occurred_at IS '実際の発生日時（視聴日、購入日など）';
COMMENT ON COLUMN public.contents.category IS 'カテゴリ（video/shopping/music/game_play等）';
COMMENT ON COLUMN public.contents.service IS 'サービス名（youtube/amazon/spotify等）';
COMMENT ON COLUMN public.contents.brand_or_store IS 'ブランドまたは店舗名';

-- 6) RLSポリシー更新（既存ポリシーがある場合）
-- search_indexビューへのアクセス許可
GRANT SELECT ON public.search_index TO authenticated;

