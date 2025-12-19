-- Status:: in-progress
-- Source-of-Truth:: supabase/migrations/20251128_intake_metrics.sql
-- Spec-State:: 確定済み
-- Last-Updated:: 2025-11-28

create extension if not exists "pgcrypto";

create table if not exists public.intake_metrics (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id text,
  star_id text,
  success boolean not null,
  latency_ms integer,
  cache_hit text not null check (cache_hit in ('none','groq','youtube','both')),
  error_code text,
  source text not null default 'youtube_ocr'
);

create index if not exists idx_intake_metrics_created_at
  on public.intake_metrics (created_at desc);
create index if not exists idx_intake_metrics_source
  on public.intake_metrics (source, created_at desc);

alter table public.intake_metrics enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'intake_metrics'
      and policyname = 'intake_metrics_insert'
  ) then
    create policy intake_metrics_insert on public.intake_metrics
      for insert
      to authenticated
      with check (true);
  end if;
end $$;

comment on table public.intake_metrics is 'Intake telemetry metrics';



