-- Status:: in-progress
-- Source-of-Truth:: supabase/migrations/20251201_intake_metrics_views.sql
-- Spec-State:: 確定済み
-- Last-Updated:: 2025-12-01

create or replace view public.intake_metrics_daily_summary as
select
  date_trunc('day', created_at) as day,
  count(*) filter (where success) as total_success,
  count(*) filter (where not success) as total_failure,
  count(*) as total_requests,
  avg(latency_ms) filter (where latency_ms is not null) as avg_latency_ms,
  count(*) filter (where error_code = 'rate_limited') as rate_limited_count,
  count(*) filter (where cache_hit = 'groq') as groq_cache_hits,
  count(*) filter (where cache_hit = 'youtube') as youtube_cache_hits,
  count(*) filter (where cache_hit = 'both') as both_cache_hits
from public.intake_metrics
group by 1
order by 1 desc;

create or replace view public.intake_metrics_by_star as
select
  star_id,
  date_trunc('day', created_at) as day,
  count(*) as total_requests,
  round(
    (count(*) filter (where success)::numeric / nullif(count(*), 0)) * 100,
    2
  ) as success_rate,
  avg(latency_ms) filter (where latency_ms is not null) as avg_latency_ms
from public.intake_metrics
where star_id is not null
group by 1, 2
order by 3 desc;

create index if not exists idx_intake_metrics_star_day
  on public.intake_metrics (star_id, created_at desc);

comment on view public.intake_metrics_daily_summary is
  'Per-day aggregates that feed the Intake ops console';
comment on view public.intake_metrics_by_star is
  'Per-star (hashed) usage metrics';



