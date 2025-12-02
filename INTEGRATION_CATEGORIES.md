# 統合カテゴリ別適用候補リスト（準備中）

作成日: 2025-11-29

## カテゴリ1: YouTube視聴カード機能

### 対象ファイル（APIから）
- [ ] `lib/features/data_integration/models/youtube_watch_detail_entry.dart`
- [ ] `lib/features/data_integration/models/youtube_preview_entry.dart`
- [ ] `lib/features/data_integration/navigation/youtube_navigation.dart`
- [ ] `lib/features/data_integration/widgets/youtube_watch_card.dart`
- [ ] `lib/features/data_integration/widgets/youtube_watch_section.dart`
- [ ] `lib/features/data_integration/screens/youtube_watch_detail_page.dart`
- [ ] `lib/features/data_integration/services/youtube_analytics.dart`

### 依存関係
- Intake API改善機能（カテゴリ2）との統合が必要

### 優先度
⭐⭐⭐⭐⭐ (最高)

---

## カテゴリ2: Intake API 改善（failover/metrics/rate-limit）

### 対象ファイル（APIから）
- [ ] `supabase/functions/intake/_shared/lib/failover-core.ts`
- [ ] `supabase/functions/intake/_shared/lib/metrics-core.ts`
- [ ] `supabase/functions/intake/_shared/lib/rate-core.ts`
- [ ] `supabase/functions/intake/_shared/metrics.ts`
- [ ] `supabase/functions/intake/_shared/rate.ts`
- [ ] `supabase/migrations/20251128_intake_metrics.sql`
- [ ] `supabase/migrations/20251201_intake_metrics_views.sql`
- [ ] `__tests__/failover-core.test.ts`
- [ ] `__tests__/intake-handler-integration.test.ts`
- [ ] `__tests__/intake-metrics-core.test.ts`
- [ ] `__tests__/intake-rate-limit.test.ts`

### 依存関係
- データベースマイグレーションの適用が必要
- 既存のIntake APIハンドラーとの統合が必要

### 優先度
⭐⭐⭐⭐⭐ (最高)

---

## カテゴリ3: テレメトリー全般

### 対象ファイル（Windsurfから）
- [ ] `lib/core/telemetry/prod_search_telemetry.dart`
- [ ] `lib/core/telemetry/search_telemetry.dart`
- [ ] `lib/core/telemetry/star_data_telemetry.dart`

### 依存関係
- 既存のテレメトリー機能との統合が必要

### 優先度
⭐⭐⭐⭐ (高)

---

## カテゴリ4: Navigation / Provider / Repository 差分

### 対象ファイル（APIから）
- [ ] `lib/features/data_integration/navigation/music_navigation.dart` (変更)
- [ ] `lib/features/data_integration/navigation/shopping_navigation.dart` (変更)
- [ ] `lib/features/data_integration/providers/music_history_provider.dart` (新規)
- [ ] `lib/features/data_integration/providers/shopping_history_provider.dart` (新規)
- [ ] `lib/features/data_integration/repositories/music_history_repository.dart` (新規)
- [ ] `lib/features/data_integration/repositories/shopping_history_repository.dart` (新規)
- [ ] `lib/features/data_integration/models/music_detail_args.dart` (新規)
- [ ] `lib/features/data_integration/models/shopping_detail_args.dart` (新規)

### 依存関係
- 既存のNavigation設定との統合が必要
- ルーティング設定の更新が必要

### 優先度
⭐⭐⭐⭐ (高)

---

## カテゴリ5: Flutterコア（テーマ / HTTPクライアント）

### 対象ファイル（Windsurfから）
- [ ] `lib/core/theme/app_theme.dart`
- [ ] `lib/core/network/http_client.dart`
- [ ] `lib/core/errors/data_fetch_exception.dart` (API/Windsurf両方)

### 依存関係
- 既存のCore機能との統合が必要

### 優先度
⭐⭐⭐ (中)

---

## カテゴリ6: テザーサイト（React）

### 対象ファイル（API/Windsurfから）
- [ ] `app/teaser/StarSignUpLPRedesign.tsx` (変更 - 要確認)
- [ ] `app/teaser/estimateProfit.ts` (変更 - 要確認)

### 依存関係
- 本番の最新版との比較が必要
- 競合解決が必要な可能性が高い

### 優先度
⭐⭐⭐ (中 - 慎重に)

---

## カテゴリ7: その他の差分ファイル

### 対象ファイル（APIから）
- [ ] `lib/config/auth0_config.dart`
- [ ] `lib/config/debug_flags.dart`
- [ ] `lib/config/environment_config.dart`
- [ ] `lib/config/runtime_flags.dart`
- [ ] `lib/config/ui_flags.dart`
- [ ] `lib/consts/debug_flags.dart`
- [ ] `docs/intake/ACCEPTANCE_CRITERIA.md`
- [ ] `docs/features/data_packs_shopping_music.md`
- [ ] `docs/features/youtube_watch_card.md`
- [ ] `docs/ops/FLUTTER_ANALYZE_KNOWN_ISSUES.md`
- [ ] `docs/ops/NEXT_BUILD_KNOWN_ISSUES.md`

### 対象ファイル（Windsurfから）
- [ ] `test/features/auth/auth_provider_test.dart`
- [ ] `test/features/auth/terms_agreement_test.dart`
- [ ] `test/features/auth_test.dart`
- [ ] `test/features/content/content_provider_test.dart`
- [ ] `test/features/content_test.dart`
- [ ] `test/features/feed/optimized_content_feed_view_model_test.dart`
- [ ] `test/features/feed/virtualized_content_feed_test.dart`
- [ ] `test/features/monetization_test.dart`
- [ ] `test/features/search/search_provider_test.dart`
- [ ] `test/features/subscription/subscription_provider_test.dart`
- [ ] `lib/data/mock_content/hanayama_posts.dart`
- [ ] `lib/data/mock_data.dart`
- [ ] `lib/data/mock_posts/fujiwara_nomii_posts.dart`

### 優先度
⭐⭐⭐ (中)

---

## 統合順序（推奨）

1. **カテゴリ2**: Intake API改善（基盤機能）
2. **カテゴリ1**: YouTube視聴カード機能（カテゴリ2に依存）
3. **カテゴリ4**: Navigation / Provider / Repository
4. **カテゴリ3**: テレメトリー全般
5. **カテゴリ5**: Flutterコア
6. **カテゴリ7**: その他の差分ファイル
7. **カテゴリ6**: テザーサイト（最後に慎重に）

---

## 注意事項

- 各カテゴリの統合前に、依存関係を確認
- データベースマイグレーションは順序を守る
- 統合後は必ずテストを実行
- 競合が発生した場合は、本番の最新版を基準に判断


