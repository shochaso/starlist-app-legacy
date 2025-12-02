-- RPC to fetch visible star data items for a specific star/date
CREATE OR REPLACE FUNCTION public.get_star_data_items(
  p_star_id TEXT,
  p_occurred_at DATE,
  p_category TEXT DEFAULT NULL,
  p_genre TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  username TEXT,
  category TEXT,
  genre TEXT,
  title TEXT,
  thumbnail_url TEXT,
  occurred_at DATE,
  created_at TIMESTAMPTZ,
  metadata JSONB
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    id,
    star_id AS username,
    category,
    genre,
    title,
    COALESCE(raw_payload ->> 'thumbnail_url', raw_payload ->> 'thumbnail') AS thumbnail_url,
    occurred_at,
    created_at,
    raw_payload AS metadata
  FROM public.star_data_items
  WHERE star_id = p_star_id
    AND occurred_at = p_occurred_at
    AND is_hidden = FALSE
    AND (p_category IS NULL OR category = p_category)
    AND (p_genre IS NULL OR genre = p_genre)
  ORDER BY occurred_at DESC, created_at DESC;
$$;
