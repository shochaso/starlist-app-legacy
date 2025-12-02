-- Status:: in-progress
-- Source-of-Truth:: supabase/migrations/20251108_subscriptions_plan_price.sql
-- Spec-State:: 確定済み（Stripe整合・サブスクリプション金額履歴保持）
-- Last-Updated:: 2025-11-08

-- Stripe整合：サブスクリプション金額の履歴保持
alter table if exists public.subscriptions
  add column if not exists plan_price integer,        -- 税込JPY（円）
  add column if not exists currency   text default 'JPY';

-- コメント追加
comment on column public.subscriptions.plan_price is '購入時の税込価格（JPY）。価格改定時も当時の金額を保持';
comment on column public.subscriptions.currency is '通貨コード（デフォルト: JPY）';

-- Webhook 実装方針（抜粋）：
-- checkout.session.completed / customer.subscription.updated
-- → event.data.object.amount_total などから当時の税込円を算出して plan_price に保存
-- （Stripe金額が「最小通貨単位（¢）」なら /100 して整数の円に丸める）


-- Source-of-Truth:: supabase/migrations/20251108_subscriptions_plan_price.sql
-- Spec-State:: 確定済み（Stripe整合・サブスクリプション金額履歴保持）
-- Last-Updated:: 2025-11-08

-- Stripe整合：サブスクリプション金額の履歴保持
alter table if exists public.subscriptions
  add column if not exists plan_price integer,        -- 税込JPY（円）
  add column if not exists currency   text default 'JPY';

-- コメント追加
comment on column public.subscriptions.plan_price is '購入時の税込価格（JPY）。価格改定時も当時の金額を保持';
comment on column public.subscriptions.currency is '通貨コード（デフォルト: JPY）';

-- Webhook 実装方針（抜粋）：
-- checkout.session.completed / customer.subscription.updated
-- → event.data.object.amount_total などから当時の税込円を算出して plan_price に保存
-- （Stripe金額が「最小通貨単位（¢）」なら /100 して整数の円に丸める）


