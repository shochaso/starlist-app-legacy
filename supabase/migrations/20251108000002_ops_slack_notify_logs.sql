-- Status:: planned
-- Source-of-Truth:: supabase/migrations/20251108_ops_slack_notify_logs.sql
-- Spec-State:: 確定済み（Slack通知監査ログ）
-- Last-Updated:: 2025-11-08

-- OPS Slack Notify logs table for audit and tracking
create table if not exists public.ops_slack_notify_logs (
  id bigserial primary key,
  level text not null check (level in ('NORMAL','WARNING','CRITICAL')),
  success_rate numeric,
  p95_ms integer,
  error_count integer,
  payload jsonb not null,         -- Slack送信本文（整形済み）
  delivered boolean not null,      -- Slack側200か？
  response_status integer,         -- Slackレスポンスコード
  response_body text,              -- Slackレスポンス本文
  inserted_at timestamptz not null default now()
);

-- Indexes for efficient querying
create index if not exists idx_ops_slack_notify_logs_inserted_at 
  on public.ops_slack_notify_logs (inserted_at desc);

create index if not exists idx_ops_slack_notify_logs_level 
  on public.ops_slack_notify_logs (level);

-- RLS
alter table public.ops_slack_notify_logs enable row level security;

-- Policy: authenticated users can read all Slack notify logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_slack_notify_logs' 
    and policyname = 'ops_slack_notify_logs_select'
  ) then
    create policy ops_slack_notify_logs_select on public.ops_slack_notify_logs
      for select to authenticated
      using (true);
  end if;
end $$;

-- Policy: Edge Functions can insert Slack notify logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_slack_notify_logs' 
    and policyname = 'ops_slack_notify_logs_insert_edge'
  ) then
    create policy ops_slack_notify_logs_insert_edge on public.ops_slack_notify_logs
      for insert to authenticated
      with check (true); -- Edge Functions use service role key
  end if;
end $$;


-- Source-of-Truth:: supabase/migrations/20251108_ops_slack_notify_logs.sql
-- Spec-State:: 確定済み（Slack通知監査ログ）
-- Last-Updated:: 2025-11-08

-- OPS Slack Notify logs table for audit and tracking
create table if not exists public.ops_slack_notify_logs (
  id bigserial primary key,
  level text not null check (level in ('NORMAL','WARNING','CRITICAL')),
  success_rate numeric,
  p95_ms integer,
  error_count integer,
  payload jsonb not null,         -- Slack送信本文（整形済み）
  delivered boolean not null,      -- Slack側200か？
  response_status integer,         -- Slackレスポンスコード
  response_body text,              -- Slackレスポンス本文
  inserted_at timestamptz not null default now()
);

-- Indexes for efficient querying
create index if not exists idx_ops_slack_notify_logs_inserted_at 
  on public.ops_slack_notify_logs (inserted_at desc);

create index if not exists idx_ops_slack_notify_logs_level 
  on public.ops_slack_notify_logs (level);

-- RLS
alter table public.ops_slack_notify_logs enable row level security;

-- Policy: authenticated users can read all Slack notify logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_slack_notify_logs' 
    and policyname = 'ops_slack_notify_logs_select'
  ) then
    create policy ops_slack_notify_logs_select on public.ops_slack_notify_logs
      for select to authenticated
      using (true);
  end if;
end $$;

-- Policy: Edge Functions can insert Slack notify logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_slack_notify_logs' 
    and policyname = 'ops_slack_notify_logs_insert_edge'
  ) then
    create policy ops_slack_notify_logs_insert_edge on public.ops_slack_notify_logs
      for insert to authenticated
      with check (true); -- Edge Functions use service role key
  end if;
end $$;


