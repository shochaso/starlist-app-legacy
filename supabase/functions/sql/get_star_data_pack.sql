-- RPC to fetch aggregated pack details by its generated identifier
CREATE OR REPLACE FUNCTION public.get_star_data_pack(
  p_pack_id TEXT
)
RETURNS TABLE (
  pack_id TEXT,
  created_at TIMESTAMPTZ,
  items JSONB
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  WITH parsed AS (
    SELECT
      split_part(p_pack_id, '::', 1) AS star_id,
      to_date(split_part(p_pack_id, '::', 2), 'YYYY-MM-DD') AS target_date
  )
  SELECT
    p_pack_id AS pack_id,
    COALESCE(MAX(sdi.created_at), NOW()) AS created_at,
    COALESCE(
      JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'id', sdi.id,
          'username', sdi.star_id,
          'category', sdi.category,
          'genre', sdi.genre,
          'title', sdi.title,
          'thumbnailUrl', COALESCE(sdi.raw_payload ->> 'thumbnail_url', sdi.raw_payload ->> 'thumbnail'),
          'date', sdi.occurred_at,
          'createdAt', sdi.created_at,
          'metadata', COALESCE(sdi.raw_payload, '{}'::jsonb)
        ) ORDER BY sdi.created_at DESC
      ) FILTER (WHERE sdi.id IS NOT NULL),
      '[]'::jsonb
    ) AS items
  FROM parsed
  LEFT JOIN public.star_data_items sdi ON sdi.star_id = parsed.star_id
    AND sdi.occurred_at = parsed.target_date
    AND sdi.is_hidden = FALSE
  WHERE parsed.star_id IS NOT NULL AND parsed.target_date IS NOT NULL
  GROUP BY p_pack_id;
$$;
