-- Status:: planned
-- Source-of-Truth:: supabase/migrations/20251107_ops_summary_email_logs.sql
-- Spec-State:: 確定済み
-- Last-Updated:: 2025-11-07

-- OPS Summary Email logs table for audit and idempotency
create table if not exists public.ops_summary_email_logs (
  id bigserial primary key,
  report_week text not null, -- YYYY-Wnn format (e.g., "2025-W45")
  channel text not null default 'email',
  provider text not null, -- 'resend' or 'sendgrid'
  run_id text,
  message_id text,
  to_count integer not null,
  subject text not null,
  sent_at_utc timestamptz not null default now(),
  sent_at_jst timestamptz, -- Calculated JST timestamp
  duration_ms integer,
  ok boolean not null,
  error_code text,
  error_message text,
  unique(report_week, channel, provider) -- Prevent duplicate sends
);

-- Indexes for efficient querying
create index if not exists idx_ops_summary_email_logs_sent_at 
  on public.ops_summary_email_logs (sent_at_utc desc);

create index if not exists idx_ops_summary_email_logs_week_provider 
  on public.ops_summary_email_logs (report_week, provider);

-- RLS
alter table public.ops_summary_email_logs enable row level security;

-- Policy: authenticated users can read all email logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_summary_email_logs' 
    and policyname = 'ops_summary_email_logs_select'
  ) then
    create policy ops_summary_email_logs_select on public.ops_summary_email_logs
      for select to authenticated
      using (true);
  end if;
end $$;

-- Policy: Edge Functions can insert email logs
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'ops_summary_email_logs' 
    and policyname = 'ops_summary_email_logs_insert_edge'
  ) then
    create policy ops_summary_email_logs_insert_edge on public.ops_summary_email_logs
      for insert to authenticated
      with check (true); -- Edge Functions use service role key
  end if;
end $$;

