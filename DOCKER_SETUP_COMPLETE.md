# Supabaseローカル環境 Docker構築完了レポート

作成日: 2025-11-29

## ✅ 作成されたファイル

### 1. docker-compose.supabase.yml
- Supabase公式構成ベースのDocker Compose設定
- 以下のサービスを含む:
  - `supabase-db` - PostgreSQL 15.1.1
  - `supabase-rest` - PostgREST API
  - `supabase-realtime` - Realtime
  - `supabase-storage` - Storage API
  - `supabase-studio` - Studio UI
  - `supabase-kong` - API Gateway
  - `supabase-edge-runtime` - Deno Edge Functions
  - `supabase-auth` - GoTrue Auth
  - `supabase-logflare` - Logs (optional)

### 2. .env.local
- 自動生成された環境変数ファイル
- 以下のキーを含む:
  - `SUPABASE_URL=http://localhost:54321`
  - `POSTGRES_PASSWORD` (自動生成)
  - `JWT_SECRET` (自動生成)
  - `ANON_KEY` (自動生成)
  - `SERVICE_ROLE_KEY` (自動生成)
  - Intake API設定

### 3. supabase/config.toml
- Supabase CLI用の設定ファイル
- Edge Functions設定を含む

### 4. supabase/kong.yml
- Kong API Gateway設定
- 各サービスへのルーティング設定

### 5. supabase/functions/intake/index.ts
- ✅ 検証・修正完了
- RateLimitErrorの適切な処理を追加
- HTTP 429レスポンスを返すように改善

### 6. setup-supabase-local.sh
- Docker Compose起動スクリプト
- マイグレーション自動実行

### 7. test-intake-api.sh
- Intake APIテストスクリプト
- ヘルスチェック、通常リクエスト、レート制限テスト

### 8. FLUTTER_SUPABASE_LOCAL_DIFF.md
- Flutterアプリ側の設定変更ガイド

## 🔧 修正内容

### intake/index.ts
- `RateLimitError`のインポートを追加
- RateLimitErrorの適切な処理を追加
- HTTP 429レスポンスと`Retry-After`ヘッダーを返すように改善

## 📋 起動手順

### 方法1: Docker Compose（推奨）

```bash
# 1. Docker Desktopを起動
# 2. 環境変数を設定（.env.localが既に作成済み）
# 3. 起動
./setup-supabase-local.sh

# または手動で
docker compose -f docker-compose.supabase.yml up -d
```

### 方法2: Supabase CLI

```bash
# Supabase CLIを使用（より簡単）
./setup-supabase-cli.sh

# または手動で
supabase start
```

## 🧪 動作確認

### 1. サービス起動確認

```bash
# コンテナの状態確認
docker compose -f docker-compose.supabase.yml ps

# ログ確認
docker compose -f docker-compose.supabase.yml logs -f supabase_edge_runtime_starlist
```

### 2. Intake APIテスト

```bash
# テストスクリプトを実行
./test-intake-api.sh

# または手動で
curl -X POST http://localhost:54321/functions/v1/intake \
  -H "Content-Type: application/json" \
  -d '{"ocrText": "test"}'
```

### 3. Supabase Studio確認

ブラウザで http://localhost:54323 にアクセス

## 🔑 環境変数の設定

`.env.local`に以下のAPIキーを設定してください:

```bash
GROQ_API_KEY=your-groq-api-key
YOUTUBE_API_KEY=your-youtube-api-key
```

## 📱 Flutterアプリ側の設定

詳細は `FLUTTER_SUPABASE_LOCAL_DIFF.md` を参照してください。

### クイック設定

```bash
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=hhZCOuXtaN69ZtpORFubZ5vZp6IBG5UvYmpK_8cap0E
```

### 注意事項

- **iOS Simulator**: `localhost` → `127.0.0.1`
- **Android Emulator**: `localhost` → `10.0.2.2`
- **実機**: 開発マシンのIPアドレスを使用（例: `http://192.168.1.100:54321`）

## 🐛 トラブルシューティング

### Dockerが起動しない場合

```bash
# Docker Desktopが起動しているか確認
docker info

# コンテナのログを確認
docker compose -f docker-compose.supabase.yml logs
```

### ポートが既に使用されている場合

`.env.local`と`docker-compose.supabase.yml`のポート番号を変更してください。

### Edge Functionsが動作しない場合

```bash
# Edge Runtimeのログを確認
docker logs supabase_edge_runtime_starlist

# 環境変数を確認
docker exec supabase_edge_runtime_starlist env | grep INTAKE
```

## 📊 データベースマイグレーション

マイグレーションは自動実行されますが、手動で実行する場合:

```bash
# マイグレーションを適用
docker exec -i supabase_db_starlist psql -U supabase_admin -d postgres < supabase/migrations/20251128_intake_metrics.sql
docker exec -i supabase_db_starlist psql -U supabase_admin -d postgres < supabase/migrations/20251201_intake_metrics_views.sql
```

## ✅ 動作確認チェックリスト

- [ ] Docker Desktopが起動している
- [ ] `docker compose -f docker-compose.supabase.yml up -d`が成功
- [ ] http://localhost:54323 でSupabase Studioにアクセスできる
- [ ] http://localhost:54321/functions/v1/intake にリクエストを送信できる
- [ ] レート制限が正常に動作する（6回目のリクエストで429エラー）
- [ ] メトリクスが`intake_metrics`テーブルに記録される
- [ ] Flutterアプリから接続できる

## 🎯 次のステップ

1. Docker Desktopをインストール・起動
2. `./setup-supabase-local.sh`を実行
3. `./test-intake-api.sh`で動作確認
4. Flutterアプリの設定を更新
5. FlutterアプリからIntake APIをテスト

---

## 📝 ファイル一覧

- `docker-compose.supabase.yml` - Docker Compose設定
- `.env.local` - 環境変数
- `supabase/config.toml` - Supabase CLI設定
- `supabase/kong.yml` - Kong設定
- `supabase/functions/intake/index.ts` - Intake API（修正済み）
- `setup-supabase-local.sh` - 起動スクリプト
- `test-intake-api.sh` - テストスクリプト
- `FLUTTER_SUPABASE_LOCAL_DIFF.md` - Flutter設定ガイド


