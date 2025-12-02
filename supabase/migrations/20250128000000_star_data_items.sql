-- StarData items table for storing star activity data (YouTube views, shopping, music, etc.)
-- Created: 2025-01-28

CREATE TABLE IF NOT EXISTS public.star_data_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  star_id TEXT NOT NULL,
  category TEXT NOT NULL,
  genre TEXT,
  title TEXT NOT NULL,
  subtitle TEXT,
  source TEXT,
  occurred_at DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  raw_payload JSONB
);

-- Index for efficient queries by star_id and date
CREATE INDEX IF NOT EXISTS idx_star_data_items_star_id_occurred_at
  ON public.star_data_items (star_id, occurred_at DESC);

-- Index for category filtering
CREATE INDEX IF NOT EXISTS idx_star_data_items_category
  ON public.star_data_items (category);

-- Enable RLS
ALTER TABLE public.star_data_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- TODO: Implement proper RLS policies based on actual requirements
-- Example policies (DO NOT use in production without review):

-- Allow stars to read their own data
CREATE POLICY "Stars can read their own star_data_items"
  ON public.star_data_items
  FOR SELECT
  TO authenticated
  USING (
    star_id = (
      SELECT username FROM public.profiles
      WHERE id = auth.uid()
    )
    OR star_id = auth.uid()::text
  );

-- Allow stars to insert their own data
CREATE POLICY "Stars can insert their own star_data_items"
  ON public.star_data_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    star_id = (
      SELECT username FROM public.profiles
      WHERE id = auth.uid()
    )
    OR star_id = auth.uid()::text
  );

-- Allow public read for now (adjust based on requirements)
-- TODO: Restrict to followers or paid subscribers based on business logic
CREATE POLICY "Public can read star_data_items"
  ON public.star_data_items
  FOR SELECT
  TO anon, authenticated
  USING (true);


