# 3フォルダ差分分析レポート

作成日: 2025-11-29

## 分析対象フォルダ

1. **本番**: `/Users/shochaso/Downloads/starlist-app` (現在のワークスペース)
2. **API**: `/Users/shochaso/Downloads/starlist-app API`
3. **Windsurf**: `/Users/shochaso/Downloads/starlist-app Windsurf`

---

## API → 本番との差分まとめ

### 追加されたファイル

#### Flutter / Data Integration関連
- `lib/features/data_integration/models/youtube_watch_detail_entry.dart` - YouTube視聴詳細エントリモデル
- `lib/features/data_integration/models/youtube_preview_entry.dart` - YouTubeプレビューエントリモデル
- `lib/features/data_integration/models/intake_response.dart` - Intake APIレスポンスモデル
- `lib/features/data_integration/models/music_detail_args.dart` - 音楽詳細画面引数
- `lib/features/data_integration/models/shopping_detail_args.dart` - ショッピング詳細画面引数
- `lib/features/data_integration/navigation/youtube_navigation.dart` - YouTube詳細画面へのナビゲーション
- `lib/features/data_integration/widgets/youtube_watch_card.dart` - YouTube視聴カードウィジェット（v1.1.1）
- `lib/features/data_integration/widgets/youtube_watch_section.dart` - YouTube視聴セクション
- `lib/features/data_integration/providers/music_history_provider.dart` - 音楽履歴プロバイダー
- `lib/features/data_integration/providers/shopping_history_provider.dart` - ショッピング履歴プロバイダー
- `lib/features/data_integration/repositories/music_history_repository.dart` - 音楽履歴リポジトリ
- `lib/features/data_integration/repositories/shopping_history_repository.dart` - ショッピング履歴リポジトリ
- `lib/features/data_integration/services/youtube_analytics.dart` - YouTube分析サービス
- `lib/features/data_integration/screens/youtube_watch_detail_page.dart` - YouTube視聴詳細ページ

#### Supabase / Intake API関連
- `supabase/functions/intake/_shared/lib/failover-core.ts` - LLMフォールバック機能
- `supabase/functions/intake/_shared/lib/metrics-core.ts` - メトリクス収集コア
- `supabase/functions/intake/_shared/lib/rate-core.ts` - レート制限コア
- `supabase/functions/intake/_shared/metrics.ts` - メトリクスヘルパー
- `supabase/functions/intake/_shared/rate.ts` - レート制限ヘルパー
- `supabase/migrations/20251128_intake_metrics.sql` - Intakeメトリクステーブル
- `supabase/migrations/20251201_intake_metrics_views.sql` - Intakeメトリクスビュー

#### テストファイル
- `__tests__/failover-core.test.ts` - フォールバック機能テスト
- `__tests__/intake-handler-integration.test.ts` - Intakeハンドラー統合テスト
- `__tests__/intake-metrics-core.test.ts` - メトリクスコアテスト
- `__tests__/intake-rate-limit.test.ts` - レート制限テスト

#### ドキュメント
- `docs/intake/ACCEPTANCE_CRITERIA.md` - Intake v1.2 受け入れ基準
- `docs/features/data_packs_shopping_music.md` - ショッピング・音楽データパック仕様
- `docs/features/youtube_watch_card.md` - YouTube視聴カードUI仕様
- `docs/ops/FLUTTER_ANALYZE_KNOWN_ISSUES.md` - Flutter分析既知の問題
- `docs/ops/NEXT_BUILD_KNOWN_ISSUES.md` - Next.jsビルド既知の問題
- `docs/deploy/` - デプロイ関連ドキュメント

#### その他
- `lib/config/` ディレクトリ（auth0_config, debug_flags, environment_config, runtime_flags, ui_flags）
- `lib/consts/debug_flags.dart` - デバッグフラグ定数
- `lib/core/errors/data_fetch_exception.dart` - データ取得例外

### 変更されたファイル

#### Flutter / Navigation
- `lib/features/data_integration/navigation/music_navigation.dart`
  - `MusicDetailArgs` を別ファイルに分離
  - `navigateToMusicDetail` を `async` 関数に変更
  - ルート名を定数化

- `lib/features/data_integration/navigation/shopping_navigation.dart`
  - 同様の変更（Args分離、async化、ルート名定数化）

- `lib/core/navigation/app_router.dart` - ルーティング設定の変更
- `lib/core/navigation/star_data_navigation.dart` - StarDataナビゲーションの変更

#### React / Next.js / テザーサイト
- `app/teaser/StarSignUpLPRedesign.tsx`
  - 大幅なUI変更（ロゴ削除、機能紹介の文言変更）
  - `estimateRevenue` → `estimateProfit` への変更
  - カテゴリ・ジャンル選択UIの変更

- `app/teaser/estimateProfit.ts` - 収益計算ロジックの変更

#### Supabase Functions
- `supabase/functions/intake/_shared/handler.ts` - ハンドラーの改善
- `supabase/functions/intake/_shared/groq.ts` - Groqクライアントの改善
- `supabase/functions/intake/_shared/parser.ts` - パーサーの改善
- `supabase/functions/intake/_shared/youtube.ts` - YouTubeエンリッチメントの改善

#### その他
- `app/api/youtube-intake/route.ts` - APIルートの変更
- `app/lib/youtubeEnrich.ts` - YouTubeエンリッチメントの変更
- `app/lib/parseYoutubeOCR.ts` - OCRパーサーの変更

### この中で本番に絶対取り込みたいもの

#### 高優先度（必須）
1. **YouTube視聴カード機能一式**
   - `youtube_watch_card.dart`, `youtube_watch_section.dart`
   - `youtube_watch_detail_entry.dart`, `youtube_navigation.dart`
   - `youtube_watch_detail_page.dart`
   - → 新機能として本番に必須

2. **Intake API改善機能**
   - `failover-core.ts`, `metrics-core.ts`, `rate-core.ts`
   - `intake_metrics.sql`, `intake_metrics_views.sql`
   - → 運用安定性向上のため必須

3. **Providers/Repositories**
   - `music_history_provider.dart`, `shopping_history_provider.dart`
   - `music_history_repository.dart`, `shopping_history_repository.dart`
   - → データ管理の改善

4. **テストファイル一式**
   - `__tests__/failover-core.test.ts`
   - `__tests__/intake-handler-integration.test.ts`
   - `__tests__/intake-metrics-core.test.ts`
   - `__tests__/intake-rate-limit.test.ts`
   - → 品質保証のため必須

5. **ドキュメント**
   - `docs/intake/ACCEPTANCE_CRITERIA.md`
   - `docs/features/youtube_watch_card.md`
   - → 開発・運用の参考資料として重要

#### 中優先度（推奨）
6. **Navigation改善**
   - `music_navigation.dart`, `shopping_navigation.dart` の改善版
   - Args分離、async化による保守性向上

7. **Config/Consts整理**
   - `lib/config/` ディレクトリの整理
   - デバッグフラグの一元管理

### 逆に古くて不要なもの

- 特に明確な「不要」なものは見当たりませんが、以下は確認が必要：
  - `app/teaser/StarSignUpLPRedesign.tsx` の変更は、本番の最新版と比較してどちらが新しいか要確認
  - 本番に既に存在する機能と重複する可能性があるものは、統合時に競合解決が必要

---

## Windsurf → 本番との差分まとめ

### 追加されたファイル

#### Flutter / Core機能
- `lib/core/telemetry/prod_search_telemetry.dart` - 本番検索テレメトリー
- `lib/core/telemetry/search_telemetry.dart` - 検索テレメトリー
- `lib/core/telemetry/star_data_telemetry.dart` - StarDataテレメトリー
- `lib/core/theme/app_theme.dart` - アプリテーマ
- `lib/core/network/http_client.dart` - HTTPクライアント
- `lib/core/prefs/` 関連の改善版（既存ファイルの拡張）

#### テストファイル
- `test/features/auth/auth_provider_test.dart` - 認証プロバイダーテスト
- `test/features/auth/terms_agreement_test.dart` - 利用規約同意テスト
- `test/features/auth_test.dart` - 認証テスト
- `test/features/content/content_provider_test.dart` - コンテンツプロバイダーテスト
- `test/features/content_test.dart` - コンテンツテスト
- `test/features/feed/optimized_content_feed_view_model_test.dart` - フィード最適化テスト
- `test/features/feed/virtualized_content_feed_test.dart` - 仮想化フィードテスト
- `test/features/monetization_test.dart` - 収益化テスト
- `test/features/search/search_provider_test.dart` - 検索プロバイダーテスト
- `test/features/subscription/subscription_provider_test.dart` - サブスクリプションテスト

#### モックデータ
- `lib/data/mock_content/hanayama_posts.dart` - モック投稿データ
- `lib/data/mock_data.dart` - モックデータ
- `lib/data/mock_posts/fujiwara_nomii_posts.dart` - モック投稿データ

#### その他
- `lib/core/errors/data_fetch_exception.dart` - データ取得例外（APIと同様）

### 変更されたファイル

#### React / Next.js / テザーサイト
- `app/teaser/StarSignUpLPRedesign.tsx` - テザーサイトの変更（APIと同様の傾向）
- `app/teaser/estimateProfit.ts` - 収益計算の変更

#### Supabase
- Supabase migrationsは本番とほぼ同等（最新のmigrationが本番にある）

### 本番に取り込みたい部分

#### 高優先度（必須）
1. **テレメトリー機能**
   - `lib/core/telemetry/prod_search_telemetry.dart`
   - `lib/core/telemetry/search_telemetry.dart`
   - `lib/core/telemetry/star_data_telemetry.dart`
   - → 分析・改善のためのデータ収集に重要

2. **テストファイル一式**
   - `test/features/auth/` 関連テスト
   - `test/features/content/` 関連テスト
   - `test/features/feed/` 関連テスト
   - `test/features/search/` 関連テスト
   - `test/features/subscription/` 関連テスト
   - → 品質保証のため必須

3. **Core機能の改善**
   - `lib/core/theme/app_theme.dart` - テーマの統一
   - `lib/core/network/http_client.dart` - HTTP通信の改善

#### 中優先度（推奨）
4. **モックデータ**
   - 開発・テスト用のモックデータ
   - ただし、本番に既に同等のものがある場合は不要

### 不要な部分

- 特に明確な「不要」なものは見当たりませんが、以下は確認が必要：
  - モックデータは開発環境でのみ使用する想定か、本番でも必要か要確認
  - テザーサイトの変更は、本番の最新版と比較してどちらが新しいか要確認

---

## 重要な差分の詳細

### 1. YouTube視聴カード機能（APIのみ）

**概要**: 完全なテキストベースのYouTube視聴カードUI（v1.1.1）

**主要ファイル**:
- `lib/features/data_integration/widgets/youtube_watch_card.dart`
- `lib/features/data_integration/models/youtube_watch_detail_entry.dart`
- `lib/features/data_integration/navigation/youtube_navigation.dart`

**特徴**:
- サムネイル・アイコンなしのテキスト3行プレビュー
- YouTube赤（#E50914）のCTAボタン
- 詳細画面へのナビゲーション機能

**取り込み優先度**: ⭐⭐⭐⭐⭐（最高）

### 2. Intake API改善（APIのみ）

**概要**: レート制限、メトリクス、フォールバック機能の実装

**主要ファイル**:
- `supabase/functions/intake/_shared/lib/failover-core.ts`
- `supabase/functions/intake/_shared/lib/metrics-core.ts`
- `supabase/functions/intake/_shared/lib/rate-core.ts`
- `supabase/migrations/20251128_intake_metrics.sql`

**特徴**:
- LLMフォールバック（Groq → Secondary LLM）
- レート制限（1分/1日）
- メトリクス収集（PIIなし、ハッシュ化ID）

**取り込み優先度**: ⭐⭐⭐⭐⭐（最高）

### 3. Providers/Repositories（APIのみ）

**概要**: 音楽・ショッピング履歴の管理機能

**主要ファイル**:
- `lib/features/data_integration/providers/music_history_provider.dart`
- `lib/features/data_integration/providers/shopping_history_provider.dart`
- `lib/features/data_integration/repositories/music_history_repository.dart`
- `lib/features/data_integration/repositories/shopping_history_repository.dart`

**取り込み優先度**: ⭐⭐⭐⭐（高）

### 4. テレメトリー機能（Windsurfのみ）

**概要**: 検索・StarDataのテレメトリー収集

**主要ファイル**:
- `lib/core/telemetry/prod_search_telemetry.dart`
- `lib/core/telemetry/search_telemetry.dart`
- `lib/core/telemetry/star_data_telemetry.dart`

**取り込み優先度**: ⭐⭐⭐⭐（高）

### 5. テストファイル（API + Windsurf）

**概要**: 包括的なテストスイート

**API側**:
- Intake API関連のテスト（フォールバック、メトリクス、レート制限）

**Windsurf側**:
- フィーチャーテスト（認証、コンテンツ、フィード、検索、サブスクリプション）

**取り込み優先度**: ⭐⭐⭐⭐⭐（最高）

---

## 統合時の注意点

### 1. 競合の可能性

- **テザーサイト**: `app/teaser/StarSignUpLPRedesign.tsx` は3つのフォルダで異なる変更がある可能性
  - 本番の最新版を基準に、API/Windsurfの変更を慎重にマージ

- **Navigation**: `music_navigation.dart`, `shopping_navigation.dart` はAPIで改善されている
  - 本番の既存実装とAPIの改善版を統合

### 2. 依存関係

- YouTube視聴カード機能は、Intake APIの改善機能に依存している可能性
- Providers/Repositoriesは、既存のデータモデルと整合性を確認

### 3. データベースマイグレーション

- `20251128_intake_metrics.sql`, `20251201_intake_metrics_views.sql` は本番に適用が必要
- 本番の `20251129090000_star_data_items_soft_delete.sql` との順序を確認

### 4. テスト環境

- 統合後、全てのテストを実行して動作確認
- 特にIntake API関連のテストは必須

---

## 次のステップ（統合作業時）

1. **統合ブランチ作成**: `integration/20251129-unify`
2. **優先度順に統合**:
   - 最優先: Intake API改善、YouTube視聴カード、テストファイル
   - 高優先度: Providers/Repositories、テレメトリー
   - 中優先度: Navigation改善、Config整理
3. **競合解決**: テザーサイト、Navigationの変更を慎重にマージ
4. **動作確認**: 統合後のテスト実行と動作確認

---

## まとめ

### APIから取り込むべき主要機能
- ✅ YouTube視聴カード機能一式
- ✅ Intake API改善（フォールバック、メトリクス、レート制限）
- ✅ Providers/Repositories（音楽・ショッピング履歴）
- ✅ テストファイル一式
- ✅ ドキュメント

### Windsurfから取り込むべき主要機能
- ✅ テレメトリー機能
- ✅ テストファイル一式
- ✅ Core機能の改善（テーマ、HTTPクライアント）

### 統合時の注意
- テザーサイトの変更は慎重にマージ
- データベースマイグレーションの順序を確認
- 統合後のテスト実行を必須とする



