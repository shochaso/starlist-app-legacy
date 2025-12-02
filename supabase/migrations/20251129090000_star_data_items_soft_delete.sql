-- Add soft delete support for star_data_items
ALTER TABLE public.star_data_items
ADD COLUMN IF NOT EXISTS is_hidden boolean NOT NULL DEFAULT false;

ALTER TABLE public.star_data_items
ADD COLUMN IF NOT EXISTS hidden_at timestamptz NULL;

-- TODO(StarData): Consider partial index on (star_id, occurred_at DESC) WHERE is_hidden = false for large tables.
