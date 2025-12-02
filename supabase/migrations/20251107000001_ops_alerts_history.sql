-- Status:: planned
-- Source-of-Truth:: supabase/migrations/20251107_ops_alerts_history.sql
-- Spec-State:: 確定済み
-- Last-Updated:: 2025-11-07

-- OPS Alerts History table for health dashboard
create table if not exists public.ops_alerts_history (
  id bigserial primary key,
  alerted_at timestamptz not null default now(),
  alert_type text not null check (alert_type in ('failure_rate', 'p95_latency')),
  value numeric not null,
  threshold numeric not null,
  period_minutes integer not null,
  app text,
  env text,
  event text,
  metrics jsonb -- Store original metrics information
);

-- Indexes for efficient querying
create index if not exists idx_ops_alerts_history_alerted_at 
  on public.ops_alerts_history (alerted_at desc);

create index if not exists idx_ops_alerts_history_type_env 
  on public.ops_alerts_history (alert_type, env, alerted_at desc);

create index if not exists idx_ops_alerts_history_app_env 
  on public.ops_alerts_history (app, env, alerted_at desc);

-- RLS
alter table public.ops_alerts_history enable row level security;

-- Policy: authenticated users can read all alert history
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_alerts_history' 
    and policyname = 'ops_alerts_history_select'
  ) then
    create policy ops_alerts_history_select on public.ops_alerts_history
      for select to authenticated
      using (true);
  end if;
end $$;

-- Policy: Edge Functions can insert alert history
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_alerts_history' 
    and policyname = 'ops_alerts_history_insert_edge'
  ) then
    create policy ops_alerts_history_insert_edge on public.ops_alerts_history
      for insert to authenticated
      with check (true); -- Edge Functions use service role key
  end if;
end $$;

