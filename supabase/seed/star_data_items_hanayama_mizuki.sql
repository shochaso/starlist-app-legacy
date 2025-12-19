-- Seed data for star_hanayama_mizuki (花山瑞樹)
-- This SQL can be run after the star_data_items table migration is applied
-- Usage: psql -d your_database -f supabase/seed/star_data_items_hanayama_mizuki.sql

-- Insert sample YouTube viewing data
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_hanayama_mizuki', 'youtube', 'video_variety', 'YouTube視聴動画 1', '夜更かしバラエティ - 夜ふかしTV', 'YouTube', CURRENT_DATE - INTERVAL '3 hours', '{"channel": "夜ふかしTV", "duration": "30:00"}'::jsonb),
  ('star_hanayama_mizuki', 'youtube', 'video_bgm', 'YouTube視聴動画 2', '作業用BGMまとめ - Lofi_Ch', 'YouTube', CURRENT_DATE - INTERVAL '6 hours', '{"channel": "Lofi_Ch", "duration": "60:00"}'::jsonb),
  ('star_hanayama_mizuki', 'youtube', 'video_asmr', 'YouTube視聴動画 3', 'ASMRでひと休み - ゆる眠ちゃん', 'YouTube', CURRENT_DATE - INTERVAL '9 hours', '{"channel": "ゆる眠ちゃん", "duration": "45:00"}'::jsonb),
  ('star_hanayama_mizuki', 'youtube', 'video_variety', 'YouTube視聴動画 4', '今日のニュースまとめ', 'YouTube', CURRENT_DATE - INTERVAL '12 hours', '{"channel": "NewsChannel", "duration": "20:00"}'::jsonb);

-- Insert sample shopping data
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_hanayama_mizuki', 'shopping', 'shopping_work', '3つの商品を購入', 'ノートPCスタンド / ブルーライトカット眼鏡 / ケーブル収納ケース', 'Amazon', CURRENT_DATE - INTERVAL '1 day', '{"items": ["ノートPCスタンド", "ブルーライトカット眼鏡", "ケーブル収納ケース"], "total": 8500}'::jsonb),
  ('star_hanayama_mizuki', 'shopping', 'shopping_work', 'オフィス用品を購入', 'デスクマット / モニターアーム', 'Amazon', CURRENT_DATE - INTERVAL '2 days', '{"items": ["デスクマット", "モニターアーム"], "total": 12000}'::jsonb);

-- Insert sample music data
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_hanayama_mizuki', 'music', 'music_work', '3曲を視聴', 'ローファイ / シティポップ / アンビエントをシャッフル再生', 'Spotify', CURRENT_DATE - INTERVAL '5 hours', '{"tracks": ["Lofi Track 1", "City Pop Track 2", "Ambient Track 3"], "duration": "12:30"}'::jsonb),
  ('star_hanayama_mizuki', 'music', 'music_work', '作業用プレイリスト再生', '集中力向上BGM', 'Spotify', CURRENT_DATE - INTERVAL '1 day', '{"playlist": "集中力向上BGM", "duration": "120:00"}'::jsonb);

-- Insert additional mixed data
INSERT INTO public.star_data_items (star_id, category, genre, title, subtitle, source, occurred_at, raw_payload)
VALUES
  ('star_hanayama_mizuki', 'youtube', 'video_variety', 'YouTube視聴動画 5', 'ゲーム実況動画', 'YouTube', CURRENT_DATE - INTERVAL '15 hours', '{"channel": "GameStreamer", "duration": "90:00"}'::jsonb),
  ('star_hanayama_mizuki', 'shopping', 'shopping_work', '書籍を購入', '技術書 / デザイン本', 'Amazon', CURRENT_DATE - INTERVAL '3 days', '{"items": ["技術書", "デザイン本"], "total": 3500}'::jsonb),
  ('star_hanayama_mizuki', 'music', 'music_work', 'アーティストアルバム視聴', '最新アルバムフル再生', 'Spotify', CURRENT_DATE - INTERVAL '2 days', '{"album": "最新アルバム", "duration": "45:00"}'::jsonb),
  ('star_hanayama_mizuki', 'youtube', 'video_bgm', 'YouTube視聴動画 6', 'リラックス音楽', 'YouTube', CURRENT_DATE - INTERVAL '18 hours', '{"channel": "RelaxMusic", "duration": "60:00"}'::jsonb);

-- Verify inserted data
SELECT COUNT(*) as total_items, category, COUNT(*) as count_per_category
FROM public.star_data_items
WHERE star_id = 'star_hanayama_mizuki'
GROUP BY category
ORDER BY category;



