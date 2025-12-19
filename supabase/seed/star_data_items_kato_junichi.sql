-- Seed data for star_kato_junichi (加藤純一)
-- This SQL can be run after the star_data_items table migration is applied
-- Usage: psql -d your_database -f supabase/seed/star_data_items_kato_junichi.sql

-- Insert YouTube streaming data (game streams, chat streams)
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_kato_junichi', 'youtube', 'video_variety', '【生放送】深夜のソウルライク耐久', 'アクションゲームでひたすらボスに挑戦', 'YouTube', CURRENT_DATE - INTERVAL '3 hours', '{"channel": "加藤純一チャンネル", "duration": "180:00", "viewers": 50000}'::jsonb),
  ('star_kato_junichi', 'youtube', 'video_variety', '【雑談配信】今日の出来事', '視聴者とチャットしながら雑談', 'YouTube', CURRENT_DATE - INTERVAL '6 hours', '{"channel": "加藤純一チャンネル", "duration": "120:00", "viewers": 30000}'::jsonb),
  ('star_kato_junichi', 'youtube', 'video_variety', '【ゲーム実況】新作RPG初プレイ', '最新作を初見でプレイ', 'YouTube', CURRENT_DATE - INTERVAL '12 hours', '{"channel": "加藤純一チャンネル", "duration": "240:00", "viewers": 80000}'::jsonb),
  ('star_kato_junichi', 'youtube', 'video_variety', '【耐久配信】24時間チャレンジ', '24時間連続配信企画', 'YouTube', CURRENT_DATE - INTERVAL '1 day', '{"channel": "加藤純一チャンネル", "duration": "1440:00", "viewers": 100000}'::jsonb);

-- Insert shopping data (gaming peripherals, daily items)
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_kato_junichi', 'shopping', 'shopping_work', 'ゲーム周辺機器を購入', 'コントローラー / ヘッドセット / マイク', 'Amazon', CURRENT_DATE - INTERVAL '2 days', '{"items": ["ゲーミングコントローラー", "ワイヤレスヘッドセット", "USBマイク"], "total": 25000}'::jsonb),
  ('star_kato_junichi', 'shopping', 'shopping_work', '配信用機材を購入', 'ライティング / カメラ / ケーブル', 'Amazon', CURRENT_DATE - INTERVAL '4 days', '{"items": ["LEDライト", "Webカメラ", "HDMIケーブル"], "total": 18000}'::jsonb),
  ('star_kato_junichi', 'shopping', 'shopping_work', '日用品を購入', '飲み物 / お菓子 / インスタント食品', 'Amazon', CURRENT_DATE - INTERVAL '5 days', '{"items": ["エナジードリンク", "お菓子", "カップ麺"], "total": 5000}'::jsonb);

-- Insert music data (BGM playlists for streaming)
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_kato_junichi', 'music', 'music_work', '配信用BGMプレイリスト', '作業用・ゲーム用BGMをシャッフル再生', 'Spotify', CURRENT_DATE - INTERVAL '8 hours', '{"playlist": "配信用BGM", "duration": "300:00", "tracks": 150}'::jsonb),
  ('star_kato_junichi', 'music', 'music_work', 'リラックス音楽を視聴', '配信後のリラックスタイム', 'Spotify', CURRENT_DATE - INTERVAL '1 day', '{"playlist": "リラックス", "duration": "60:00", "tracks": 20}'::jsonb),
  ('star_kato_junichi', 'music', 'music_work', '最新ヒット曲をチェック', 'トレンドの楽曲を確認', 'Spotify', CURRENT_DATE - INTERVAL '3 days', '{"playlist": "最新ヒット", "duration": "45:00", "tracks": 15}'::jsonb);

-- Verify inserted data
SELECT COUNT(*) as total_items, category, COUNT(*) as count_per_category
FROM public.star_data_items
WHERE star_id = 'star_kato_junichi'
GROUP BY category
ORDER BY category;



