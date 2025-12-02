# StarData Supabase Schema Draft

## 概要
- StarDataViewPage で表示される各種データ（視聴履歴・購入記録・音楽リスト等）を統一的に保管するテーブルの草案
- Supabase への本番マイグレーション適用前に schema と RLS をドキュメントで共有しておく

## star_data_items テーブル案
| カラム | 型 | 備考 |
| --- | --- | --- |
| id | uuid (primary key) | UUID を自動生成（Supabase の `gen_random_uuid()` など） |
| star_id | text | スターを識別する ID（例: `star_hanayama_mizuki` または profiles テーブルの id） |
| category | text | `youtube`, `shopping`, `music`, `receipt` など |
| genre | text | `video_variety`, `shopping_work` などのサブ分類 |
| title | text | カードのメインタイトル |
| subtitle | text | 補足説明（商品名/動画チャプターなど） |
| source | text | アプリ/サービス名（例: YouTube, Amazon） |
| date | timestamptz | 実際の視聴/購入日 |
| created_at | timestamptz | Supabase が挿入日時を管理 |
| raw_payload | jsonb | Intake 側から受け取った元データの JSON |

## RLS（Row Level Security）方針（草案）
- スター本人は自分の `star_id` レコードに対して `select/insert/update` を許可
- ファン・システムは `select` のみ許可（可能な場合、StarDataViewingAccess などの横展開）
- `supabase.functions` でデータ取り込み時に `auth.uid()` を検証して `star_id` を紐づける

## 今後の対応メモ
- Intake からこのテーブルへマッピングする mapper を `lib/src/features/star_data/application/` に追加
- Mock 用データは `MockStarDataRepository` でこの構造を模倣
- `docs/dev/SUPABASE_LOCAL_DOCKER_SETUP.md` に上記テーブル名と RLS 方針を追記済み

