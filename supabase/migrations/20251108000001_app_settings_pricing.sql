-- Status:: in-progress
-- Source-of-Truth:: supabase/migrations/20251108_app_settings_pricing.sql
-- Spec-State:: 確定済み（推奨価格設定）
-- Last-Updated:: 2025-11-08

-- 1) 設定テーブル
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- 2) RLS（閲覧は全員OK、書込みはサービスロールのみ）
alter table public.app_settings enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='app_settings'
      and policyname='app_settings_select_all'
  ) then
    create policy app_settings_select_all
      on public.app_settings
      for select
      using (true);
  end if;
end $$;

-- 書込み禁止（匿名/ユーザー）。必要に応じて管理者ロールだけ許可ポリシーを追加
revoke insert, update, delete on public.app_settings from anon, authenticated;

-- 3) 取得用SQL関数
create or replace function public.get_app_setting(p_key text)
returns jsonb
language sql stable as $$
  select value from public.app_settings where key = p_key
$$;

-- 4) 初期データ（推奨価格／上下限／刻み）
insert into public.app_settings (key, value)
values (
  'pricing.recommendations',
  jsonb_build_object(
    'version','2025-11-08',
    'tiers', jsonb_build_object(
      'light',    jsonb_build_object('student',100,'adult',480),
      'standard', jsonb_build_object('student',200,'adult',1980),
      'premium',  jsonb_build_object('student',500,'adult',4980)
    ),
    'limits', jsonb_build_object(
      'student', jsonb_build_object('min',100,'max',9999),
      'adult',   jsonb_build_object('min',300,'max',29999),
      'step',    10,
      'currency','JPY',
      'tax_inclusive', true
    )
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();


-- Source-of-Truth:: supabase/migrations/20251108_app_settings_pricing.sql
-- Spec-State:: 確定済み（推奨価格設定）
-- Last-Updated:: 2025-11-08

-- 1) 設定テーブル
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- 2) RLS（閲覧は全員OK、書込みはサービスロールのみ）
alter table public.app_settings enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='app_settings'
      and policyname='app_settings_select_all'
  ) then
    create policy app_settings_select_all
      on public.app_settings
      for select
      using (true);
  end if;
end $$;

-- 書込み禁止（匿名/ユーザー）。必要に応じて管理者ロールだけ許可ポリシーを追加
revoke insert, update, delete on public.app_settings from anon, authenticated;

-- 3) 取得用SQL関数
create or replace function public.get_app_setting(p_key text)
returns jsonb
language sql stable as $$
  select value from public.app_settings where key = p_key
$$;

-- 4) 初期データ（推奨価格／上下限／刻み）
insert into public.app_settings (key, value)
values (
  'pricing.recommendations',
  jsonb_build_object(
    'version','2025-11-08',
    'tiers', jsonb_build_object(
      'light',    jsonb_build_object('student',100,'adult',480),
      'standard', jsonb_build_object('student',200,'adult',1980),
      'premium',  jsonb_build_object('student',500,'adult',4980)
    ),
    'limits', jsonb_build_object(
      'student', jsonb_build_object('min',100,'max',9999),
      'adult',   jsonb_build_object('min',300,'max',29999),
      'step',    10,
      'currency','JPY',
      'tax_inclusive', true
    )
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();


