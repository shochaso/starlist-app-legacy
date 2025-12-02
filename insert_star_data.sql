-- =========================================
-- 共通：スターID（作成済み）
-- =========================================
-- 花山瑞樹
-- \set hanayama '11111111-1111-1111-1111-111111111111'
-- 加藤純一
-- \set kato '22222222-2222-2222-2222-222222222222'

-- =========================================
-- 1. YouTube視聴データ
-- =========================================
INSERT INTO star_data_items (star_id, category, title, subtitle, occurred_at, raw_payload)
VALUES
('11111111-1111-1111-1111-111111111111', 'youtube', '【神回】深夜テンションで語る男たち', '視聴時間：12分', CURRENT_DATE, '{"channel":"夜ふかしTV","thumbnail_url":"https://i.ytimg.com/vi/4QZ9vXkA.jpg"}'::jsonb),
('11111111-1111-1111-1111-111111111111', 'youtube', 'Vlog｜朝のルーティン', '視聴時間：6分', CURRENT_DATE, '{"channel":"mizuki","thumbnail_url":"https://i.ytimg.com/vi/aa29nQBm.jpg"}'::jsonb),
('11111111-1111-1111-1111-111111111111', 'youtube', '【ニュース】今日の話題まとめ', '視聴時間：9分', CURRENT_DATE, '{"channel":"NipponNews","thumbnail_url":"https://i.ytimg.com/vi/TTx0Oj9P.jpg"}'::jsonb),

('22222222-2222-2222-2222-222222222222', 'youtube', '【APEX】ソロマスターランク挑戦', '視聴時間：22分', CURRENT_DATE, '{"channel":"Junchannel","thumbnail_url":"https://i.ytimg.com/vi/Qpp3jjgM.jpg"}'::jsonb),
('22222222-2222-2222-2222-222222222222', 'youtube', 'ただいま', '視聴時間：4分', CURRENT_DATE, '{"channel":"Junchannel","thumbnail_url":"https://i.ytimg.com/vi/QAzmdk0.jpg"}'::jsonb),
('22222222-2222-2222-2222-222222222222', 'youtube', '【雑談】近況報告', '視聴時間：11分', CURRENT_DATE, '{"channel":"Junchannel","thumbnail_url":"https://i.ytimg.com/vi/UH0t2.jpg"}'::jsonb);

-- =========================================
-- 2. Shopping（購入データ）
-- =========================================
INSERT INTO star_data_items (star_id, category, title, subtitle, occurred_at, raw_payload)
VALUES
('11111111-1111-1111-1111-111111111111', 'shopping', 'ファミマ｜メロンパン', '¥158', CURRENT_DATE, '{"store":"ファミリーマート","thumbnail_url":"https://imgur.com/bread.jpg"}'::jsonb),
('11111111-1111-1111-1111-111111111111', 'shopping', '無印良品｜バウムクーヘン', '¥240', CURRENT_DATE, '{"store":"MUJI","thumbnail_url":"https://imgur.com/baum.jpg"}'::jsonb),

('22222222-2222-2222-2222-222222222222', 'shopping', 'セブン｜大盛りナポリタン', '¥598', CURRENT_DATE, '{"store":"セブンイレブン","thumbnail_url":"https://imgur.com/pasta.jpg"}'::jsonb),
('22222222-2222-2222-2222-222222222222', 'shopping', '楽天｜ゲーミングマウス', '¥3,980', CURRENT_DATE, '{"store":"楽天市場","thumbnail_url":"https://imgur.com/mouse.jpg"}'::jsonb);

-- =========================================
-- 3. Music（楽曲視聴）
-- =========================================
INSERT INTO star_data_items (star_id, category, title, subtitle, occurred_at, raw_payload)
VALUES
('11111111-1111-1111-1111-111111111111', 'music', 'YOASOBI - 群青', '再生時間：3:45', CURRENT_DATE, '{"artist":"YOASOBI","thumbnail_url":"https://imgur.com/gunjo.jpg"}'::jsonb),
('22222222-2222-2222-2222-222222222222', 'music', 'Ado - うっせぇわ', '再生時間：3:20', CURRENT_DATE, '{"artist":"Ado","thumbnail_url":"https://imgur.com/ado.jpg"}'::jsonb);

