-- RPC to provide counts and recent category hints for a star
CREATE OR REPLACE FUNCTION public.get_star_data_summary(
  p_star_id TEXT
)
RETURNS TABLE (
  daily_count INTEGER,
  weekly_count INTEGER,
  monthly_count INTEGER,
  latest_categories TEXT[]
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  WITH visible AS (
    SELECT category, occurred_at
    FROM public.star_data_items
    WHERE star_id = p_star_id
      AND is_hidden = FALSE
  )
  SELECT
    (SELECT COUNT(*) FROM visible WHERE occurred_at = CURRENT_DATE) AS daily_count,
    (SELECT COUNT(*) FROM visible WHERE occurred_at >= CURRENT_DATE - INTERVAL '6 days') AS weekly_count,
    (SELECT COUNT(*) FROM visible WHERE occurred_at >= CURRENT_DATE - INTERVAL '29 days') AS monthly_count,
    (
      SELECT ARRAY(
        SELECT category
        FROM (
          SELECT category, MAX(occurred_at) AS latest
          FROM visible
          WHERE category IS NOT NULL
          GROUP BY category
          ORDER BY latest DESC
          LIMIT 8
        ) recent
      )
    ) AS latest_categories;
$$;
