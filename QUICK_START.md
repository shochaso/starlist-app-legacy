# 🚀 Supabase Local環境 クイックスタートガイド

## 現在の準備状況

✅ **すべて準備完了しています！**

- `.env.local` → APIキー（dummy）設定済み
- Docker Compose設定 → 作成済み
- セットアップスクリプト → 配置済み
- テストスクリプト → 配置済み

## 起動手順（3ステップ）

### ① Docker Desktopを起動

1. Launchpadを開く
2. 「Docker」をクリック
3. メニューバー右上に🐳アイコンが表示されるまで待つ（5〜10秒）

### ② Supabase Local環境を起動

```bash
./check-docker-and-setup.sh
```

このスクリプトは以下を自動実行します：
- Docker起動確認
- Supabaseコンテナ起動
- データベースマイグレーション
- サービスURL表示

### ③ 動作確認

```bash
# ステータス確認
./verify-supabase-status.sh

# Intake APIテスト
./test-intake-api.sh
```

## アクセスURL

起動後、以下のURLでアクセスできます：

- **API Gateway**: http://localhost:54321
- **Supabase Studio**: http://localhost:54323
- **Edge Functions**: http://localhost:54321/functions/v1/

## トラブルシューティング

### Docker Desktopが起動しない

```bash
# Dockerの状態確認
docker info

# エラーメッセージを確認
docker ps
```

### コンテナが起動しない

```bash
# ログを確認
docker compose -f docker-compose.supabase.yml logs

# 特定のサービスのログ
docker logs supabase_edge_runtime_starlist
```

### Intake APIが動作しない

```bash
# Edge Runtimeのログを確認
docker logs supabase_edge_runtime_starlist

# 環境変数を確認
docker exec supabase_edge_runtime_starlist env | grep INTAKE
```

## 次のステップ

1. **APIキーを設定**（`.env.local`を編集）
   ```bash
   GROQ_API_KEY=your-actual-groq-key
   YOUTUBE_API_KEY=your-actual-youtube-key
   ```

2. **Flutterアプリを接続**
   - `FLUTTER_SUPABASE_LOCAL_DIFF.md`を参照

3. **開発を開始**
   - Supabase Studioでデータベースを確認
   - Edge Functionsを開発・テスト

## 便利なコマンド

```bash
# ステータス確認
./verify-supabase-status.sh

# ログ確認（リアルタイム）
docker compose -f docker-compose.supabase.yml logs -f

# コンテナ再起動
docker compose -f docker-compose.supabase.yml restart

# すべて停止
docker compose -f docker-compose.supabase.yml down

# すべて停止＋データ削除
docker compose -f docker-compose.supabase.yml down -v
```

---

**準備完了！Docker Desktopを起動して、`./check-docker-and-setup.sh`を実行してください。**
