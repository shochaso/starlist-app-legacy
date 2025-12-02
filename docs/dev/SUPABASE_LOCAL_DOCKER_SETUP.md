# Supabase Local Docker Setup for Starlist-app

## 概要
- このリポジトリには Supabase 関連の `supabase/functions` および `supabase/migrations` ディレクトリが含まれています。
- `supabase/config.toml` はバージョン管理されていないため、Supabase CLI でローカルプロジェクトを作成し、その中で `supabase start` を実行する必要があります。
- このドキュメントでは、ローカル Supabase を Docker 上で動かし、`starlist-app` が接続するまでの手順を記載します。

---

## 前提準備
1. Docker をインストール（https://docs.docker.com/get-docker/）
2. supabase CLI をグローバルにインストール（`npm install -g supabase` または `brew install supabase/tap/supabase`）

## 新規 Supabase プロジェクトの作成
1. リポジトリルートで `supabase init` を実行（必要なら別ディレクトリで実行して `supabase` フォルダを作る）
2. `supabase/config.toml` を確認し、以下のようなデフォルト構成になっていることを確認
   ```toml
   project_id = "supabase"
   db.name = "postgres"
   db.port = 54322
   db.host = "localhost"
   ```
3. もし既存の config があれば`supabase start` の default port 54321/54322 から逸脱していないか確認する

## ローカル起動
- `supabase start` を実行すると Docker コンテナが立ち上がる（CLI が config も自動生成）
- 初回起動時は `.supabase` ディレクトリと `.env.local` を生成するため、`SUPABASE_URL`/`SUPABASE_ANON_KEY` を `.env.local` または `--dart-define` でアプリに渡す

## データリセット・マイグレーション
- `supabase db reset` を実行すると DB が初期状態（migrations を順に適用）になる
- 本リポジトリの `supabase/migrations` を `supabase` プロジェクト内にコピーしてから reset すると、オペレーション系テーブルも適用される

### StarData テーブルのシード
- reset 後に `star_data_items` 用のシードを流すことで `@hanayama-mizuki` / `@kato-junichi` の初期データを用意。以下の `psql` コマンドを `supabase` プロジェクトルートで実行する（ポート 54322 を使っていることが多いため、必要なら `-p 54322` を追記）。
  ```bash
  psql -h localhost -U postgres -d postgres -f supabase/seed/star_data_items_hanayama_mizuki.sql
  psql -h localhost -U postgres -d postgres -f supabase/seed/star_data_items_kato_junichi.sql
  ```
- Supabase CLI で `psql` に接続できない場合は `supabase db shell` を使って `\i supabase/seed/...` で読み込む方法も可。

## Flutter の Supabase本番モード起動例
- `USE_SUPABASE_STAR_DATA=true` を `--dart-define` で渡すと `starDataRepositoryProvider` が Supabase 実装に切り替わる。
- 例:
  ```bash
  flutter run -d chrome \
    --dart-define=SUPABASE_URL=http://localhost:54321 \
    --dart-define=SUPABASE_ANON_KEY=<anon-key> \
    --dart-define=USE_SUPABASE_STAR_DATA=true
  ```
- `/my/data` / `/stars/:username/data` にアクセスし、実際の `star_data_items` レコードが描画されることを確認する。DataImport（YouTube/レシート）から書き込んだ新規レコードも即座に反映される。

## 停止
- `supabase stop` で Docker コンテナを停止
- `supabase start` を再実行するとコンテナが復帰（データは `.supabase/db/data` に保存される）

## つまづきやすい点
- ポート競合：`supabase start` は 54321/54322 を使用。既存 PostgreSQL/Redis が使っていないことを確認
- CLI のバージョン差：`supabase --version` で現在 v2.51.0。最新 v2.62.10 への更新を推奨
- `.env.local` では `SUPABASE_URL` を `http://localhost:54321`、`SUPABASE_ANON_KEY` を `supabase secrets list` などから得た値に設定

## starlist-app 側接続ポイント
- `lib/config/environment_config.dart` で `SUPABASE_URL` / `SUPABASE_ANON_KEY` を参照している
- `lib/main.dart` で `EnvironmentConfig` を使って `Supabase.initialize` を呼び出している
- ローカル Supabase を使う場合、`--dart-define` もしくは `.env.local` で次の値を指定
  ```
  SUPABASE_URL=http://localhost:54321
  SUPABASE_ANON_KEY=<supabase secrets list で確認>
  ```
- `lib/src/core/config/supabase_client_provider.dart` の `supabaseClientProvider` は `Supabase.instance.client` を返し、RLS を考慮した読み取り専用操作が可能

## StarData 連携メモ (簡易)
- StarData 用テーブル（例: `star_data_items`）を Supabase 内に用意予定
- 想定カラム: `id`, `star_id`, `category`, `genre`, `title`, `subtitle`, `source`, `date`, `created_at`, `raw_payload`（JSON の自由形式）
- RLS 方針: スター本人は自分の `star_id` に対して読み書き可、ファンは `star_id` の読み取りのみ明示的に許可
