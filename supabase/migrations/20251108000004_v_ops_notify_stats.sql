-- Status:: planned
-- Source-of-Truth:: supabase/migrations/20251108_v_ops_notify_stats.sql
-- Spec-State:: 確定済み（自動閾値調整用ビュー）
-- Last-Updated:: 2025-11-08

-- View for OPS Slack Notify statistics aggregation
-- Used by ops-slack-summary Edge Function for automatic threshold calculation

CREATE OR REPLACE VIEW v_ops_notify_stats AS
SELECT
  date_trunc('day', inserted_at) AS day,
  level,
  COUNT(*) AS notification_count,
  AVG(success_rate) AS avg_success_rate,
  AVG(p95_ms) AS avg_p95_ms,
  SUM(error_count) AS total_errors,
  COUNT(*) FILTER (WHERE delivered = true) AS delivered_count,
  COUNT(*) FILTER (WHERE delivered = false) AS failed_count
FROM ops_slack_notify_logs
WHERE inserted_at >= NOW() - INTERVAL '14 days'
GROUP BY day, level
ORDER BY day DESC, level;

-- Index for efficient querying (if not exists)
CREATE INDEX IF NOT EXISTS idx_ops_slack_notify_logs_inserted_at_level 
  ON ops_slack_notify_logs (inserted_at DESC, level);

-- Grant access to authenticated users
GRANT SELECT ON v_ops_notify_stats TO authenticated;


-- Source-of-Truth:: supabase/migrations/20251108_v_ops_notify_stats.sql
-- Spec-State:: 確定済み（自動閾値調整用ビュー）
-- Last-Updated:: 2025-11-08

-- View for OPS Slack Notify statistics aggregation
-- Used by ops-slack-summary Edge Function for automatic threshold calculation

CREATE OR REPLACE VIEW v_ops_notify_stats AS
SELECT
  date_trunc('day', inserted_at) AS day,
  level,
  COUNT(*) AS notification_count,
  AVG(success_rate) AS avg_success_rate,
  AVG(p95_ms) AS avg_p95_ms,
  SUM(error_count) AS total_errors,
  COUNT(*) FILTER (WHERE delivered = true) AS delivered_count,
  COUNT(*) FILTER (WHERE delivered = false) AS failed_count
FROM ops_slack_notify_logs
WHERE inserted_at >= NOW() - INTERVAL '14 days'
GROUP BY day, level
ORDER BY day DESC, level;

-- Index for efficient querying (if not exists)
CREATE INDEX IF NOT EXISTS idx_ops_slack_notify_logs_inserted_at_level 
  ON ops_slack_notify_logs (inserted_at DESC, level);

-- Grant access to authenticated users
GRANT SELECT ON v_ops_notify_stats TO authenticated;


