-- ===========================
-- 花山瑞樹
-- ===========================

-- 1. auth.users（認証ユーザー）
insert into auth.users (id, email)
values (
    '11111111-1111-1111-1111-111111111111',
    'hanayama@example.com'
)
on conflict (id) do nothing;

-- 2. profiles（アプリ内プロフィール）
insert into profiles (id, username, full_name, email, role)
values (
    '11111111-1111-1111-1111-111111111111',
    'hanayama',
    '花山瑞樹',
    'hanayama@example.com',
    'star'
)
on conflict (id) do nothing;

-- ===========================
-- 加藤純一
-- ===========================

-- 1. auth.users（認証ユーザー）
insert into auth.users (id, email)
values (
    '22222222-2222-2222-2222-222222222222',
    'kato@example.com'
)
on conflict (id) do nothing;

-- 2. profiles（アプリ内プロフィール）
insert into profiles (id, username, full_name, email, role)
values (
    '22222222-2222-2222-2222-222222222222',
    'katojun',
    '加藤純一',
    'kato@example.com',
    'star'
)
on conflict (id) do nothing;

