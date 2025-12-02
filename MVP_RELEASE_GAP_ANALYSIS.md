# 🎯 STARLIST MVPリリース ギャップ分析レポート

**作成日**: 2025-11-30  
**分析者**: AIリファクタリング責任者  
**対象**: コードベース全体スキャン

---

## 📊 エグゼクティブサマリー

### 実装進捗状況
- **フェーズ1（MVP）**: 約60%完了
- **フェーズ2**: 約20%完了
- **フェーズ3**: 約5%完了
- **全体進捗**: 約35%完了

### クリティカルな問題
1. **Supabase RPC/DBスキーマ不整合**: 5件
2. **未実装のMVP必須機能**: 12件
3. **仮実装・未完成コード**: 23件
4. **優先度の高いバグ**: 8件

---

## 1. 📋 現在のコードが持つ機能一覧

### ✅ 実装済み機能（23機能）

#### 認証・ユーザー管理
- [x] ユーザー登録機能（メール/パスワード）
- [x] ログイン/ログアウト
- [x] プロフィール基本設定
- [x] スター/ファン区分
- [ ] **ソーシャルログイン（Google/Apple）**: 仕様のみ、実装未完了

#### データ統合
- [x] YouTube視聴履歴インポート
- [x] Spotify再生履歴インポート
- [x] レシートOCR機能（基本実装）
- [x] データインポート診断機能
- [ ] Amazon購入履歴: 未実装
- [ ] Netflix視聴履歴: 未実装

#### スターデータ管理
- [x] スターデータ表示（YouTube/Shopping/Music）
- [x] カテゴリ別フィルタリング
- [x] タイムライン表示（基本）
- [x] Supabase連携（フラグ制御）

#### ガチャ機能
- [x] ガチャ抽選ロジック
- [x] ガチャ回数管理（基本）
- [x] 広告視聴連携（部分実装）
- [ ] **ガチャRPC関数の完全統合**: 不整合あり

#### UI/UX
- [x] テーマ設定（ライト/ダーク）
- [x] ナビゲーション構造
- [x] 基本リストビュー
- [x] レスポンシブデザイン（基本）

#### 検索機能
- [x] スター検索
- [x] コンテンツ検索
- [x] タグ検索（full/tag_only mode）

#### 課金・決済
- [x] Stripe連携（基本）
- [x] サブスクリプションプラン表示
- [x] 推奨価格機能（Day11実装）
- [ ] **決済フロー完全実装**: 部分実装

#### OPS監視
- [x] Telemetry機能
- [x] OPS Dashboard
- [x] Slack通知
- [x] 週次メールレポート

---

## 2. 🚨 未実装の機能（MVPに必要なのに欠けているもの）

### P0: 緊急対応必須（MVPリリース前に必須）

#### 2.1 認証システム
- [ ] **OAuth連携（Google/Apple）**: 仕様のみ、実装未完了
  - ファイル: `lib/src/features/auth/services/auth_service.dart`
  - 問題: `auth-sync` Edge Function呼び出しなし
  - 影響: ソーシャルログインが使用不可

- [ ] **再認証/401ハンドリング**: 未実装
  - 問題: 401/403エラー時の自動再認証モーダルなし
  - 影響: セッション切れ時のUX低下

#### 2.2 ガチャシステム
- [ ] **GachaRepositoryの完全実装**: 重大な不整合
  - 問題: 提供されたコードにRPC関数のパラメータが不足
  - 詳細: 下記「5. Supabase RPC/DBスキーマ不整合」参照

#### 2.3 課金・決済
- [ ] **決済フロー完全実装**: 部分実装
  - 問題: Stripe Webhook処理が不完全
  - 影響: サブスクリプション更新が正常に動作しない可能性

- [ ] **プラン変更・アップグレード機能**: 未実装
  - 問題: プラン変更UI/ロジックが不完全

#### 2.4 データ統合
- [ ] **Amazon購入履歴取込**: 未実装
- [ ] **Netflix視聴履歴連携**: 未実装
- [ ] **データ取り込み精度向上**: 部分実装

### P1: 高優先度（リリース後早期対応）

- [ ] プロフィール画像アップロード
- [ ] プロフィール閲覧権限設定
- [ ] タイムライン表示の完全実装
- [ ] コメント機能の高度化
- [ ] リアクションシステムの拡張

---

## 3. ⚠️ 仮実装・未完成・動いていない箇所

### 3.1 ガチャ関連（重大）

#### `lib/src/features/gacha/data/gacha_limits_repository.dart`
- **問題**: 古いスキーマ（`gacha_attempts`）と新しいスキーマ（`gacha_daily_attempts`）が混在
- **行58-65**: `gacha_attempts`テーブルを参照（存在しない可能性）
- **行287**: `initialize_daily_gacha_attempts_jst3`のパラメータ名が不一致
  - コード: `user_id_param`
  - 実際: `target_user_id`

#### 提供された`GachaRepository`コード
```dart
// ❌ 問題: パラメータが不足
Future<int> initDailyAttempts() async {
  final res = await client.rpc('initialize_daily_gacha_attempts_jst3');
  // target_user_id パラメータが必要
}

Future<bool> recordAdViewAndGrant() async {
  final res = await client.rpc('complete_ad_view_and_grant_ticket');
  // target_user_id パラメータが必要
}

Future<bool> consume() async {
  final res = await client.rpc('consume_gacha_attempt_atomic');
  // target_user_id パラメータが必要
}
```

### 3.2 認証関連

#### `lib/src/features/auth/services/auth_service.dart`
- **問題**: Google/Apple OAuth未実装
- **問題**: `auth-sync` Edge Function呼び出しなし

### 3.3 データ統合関連

#### `lib/providers/youtube_history_provider.dart`
- **行249-251**: TODOコメント多数
  - エンリッチメント（サムネイル取得）未実装
  - マッチスコア計算未実装
  - コンテンツモデレーション未実装

#### `lib/src/features/youtube_easy/star_watch_history_widget.dart`
- **行367**: ファイル選択とパース処理未実装
- **行398**: URL入力ダイアログ未実装
- **行404**: 手動入力ダイアログ未実装
- **行419**: 共有設定ダイアログ未実装

### 3.4 サブスクリプション関連

#### `lib/src/features/subscription/services/subscription_validation_service.dart`
- **行22**: 機能アクセスチェック未実装
- **行31**: アップグレード資格チェック未実装
- **行40**: ダウングレード資格チェック未実装

#### `lib/src/features/subscription_service.dart`
- **行278**: 通知サービス未統合
- **行294**: 更新成功通知未実装
- **行297**: 更新失敗通知未実装
- **行307**: 期限切れ通知未実装

### 3.5 UI関連

#### `lib/theme/app_theme.dart`
- **行9**: ダークテーマが未実装（TODOコメント）

#### `lib/src/features/star_data/utils/star_id_resolver.dart`
- **行26**: 本番環境での`profiles`テーブルクエリ未実装

#### `lib/src/features/star_data/presentation/star_data_paywall_dialog.dart`
- **行174**: サブスクリプション購入フロー未統合

---

## 4. 🗑️ 古いコード・不要コード

### 4.1 重複・古い実装

#### ガチャ関連
- **`supabase_setup.sql`**: 古い`gacha_attempts`テーブル定義（行599-675）
  - 新しい`gacha_daily_attempts`（`20250722100000_gacha_ads_jst3.sql`）と重複
  - 削除推奨

#### データ統合
- **`lib/features/dat-integration/`**: 旧版データ統合（`data_integration`と重複）
  - 削除検討

#### サービス
- **`lib/services/ekyc_service.dart.bak`**: バックアップファイル
- **`lib/services/sns_verification_service.dart.bak`**: バックアップファイル
- **`lib/screens/style_guide_page.dart.bak`**: バックアップファイル

#### テスト
- **`lib/screens/test_account_switcher_screen.dart.backup`**: バックアップファイル

### 4.2 未使用の可能性があるファイル

- **`lib/starlist_mockup.dart`**: モックアップファイル（本番不要？）
- **`lib/starlist_web_mockup.dart`**: モックアップファイル（本番不要？）
- **`lib/phase4/`**: TypeScriptファイル（Flutterプロジェクト内で不要？）

---

## 5. 🔧 Supabase RPC/DBスキーマとコードの不整合箇所

### 5.1 重大な不整合

#### ❌ 問題1: ガチャRPC関数のパラメータ名不一致

**スキーマ定義** (`20250722100000_gacha_ads_jst3.sql`):
```sql
CREATE OR REPLACE FUNCTION initialize_daily_gacha_attempts_jst3(target_user_id uuid)
CREATE OR REPLACE FUNCTION complete_ad_view_and_grant_ticket(target_user_id uuid)
CREATE OR REPLACE FUNCTION consume_gacha_attempt_atomic(target_user_id uuid)
```

**コード実装** (`lib/src/features/gacha/data/gacha_limits_repository.dart`):
```dart
// ❌ パラメータ名が不一致
await _supabaseService.rpc('initialize_daily_gacha_attempts_jst3', params: {
  'user_id_param': userId,  // 正しくは 'target_user_id'
});
```

**提供されたコード**:
```dart
// ❌ パラメータが完全に欠落
Future<int> initDailyAttempts() async {
  final res = await client.rpc('initialize_daily_gacha_attempts_jst3');
  // target_user_id パラメータが必要
}
```

**修正が必要**:
- `user_id_param` → `target_user_id` に統一
- 提供された`GachaRepository`にパラメータ追加

#### ❌ 問題2: テーブル名の不整合

**新しいスキーマ**: `gacha_daily_attempts`（`20250722100000_gacha_ads_jst3.sql`）
**古いコード**: `gacha_attempts`を参照（`gacha_limits_repository.dart`行61, 144）

**影響**: コードが存在しないテーブルを参照する可能性

#### ❌ 問題3: RPC関数の戻り値型不一致

**スキーマ定義**:
- `initialize_daily_gacha_attempts_jst3`: `RETURNS void`
- `complete_ad_view_and_grant_ticket`: `RETURNS void`
- `consume_gacha_attempt_atomic`: `RETURNS boolean`

**コード実装**:
- `initDailyAttempts()`: `Future<int>`を返そうとしている（void関数）
- `recordAdViewAndGrant()`: `Future<bool>`を返そうとしている（void関数）

#### ❌ 問題4: 古いRPC関数の参照

**コード内で参照されているが、新しいスキーマに存在しない関数**:
- `get_available_gacha_attempts`: 古いスキーマ（`supabase_setup.sql`）に存在
- `add_gacha_bonus_attempts`: 古いスキーマに存在

**新しいスキーマでは**:
- `gacha_daily_attempts`テーブルを直接参照する必要がある
- または、新しいRPC関数を実装する必要がある

#### ❌ 問題5: `gacha_attempts` vs `gacha_daily_attempts`

**混在している参照**:
- `gacha_limits_repository.dart`: `gacha_attempts`を参照（行61, 144, 297）
- 新しいマイグレーション: `gacha_daily_attempts`を定義

**解決策**: 
1. すべてのコードを`gacha_daily_attempts`に統一
2. または、`gacha_attempts`テーブルを削除してマイグレーション

### 5.2 その他の不整合

#### プロフィールテーブル参照
- 一部のコードで`users`テーブルを参照している可能性
- 正しくは`profiles`テーブルを参照すべき

---

## 6. 🎨 UI仕様（最新Figma）とのズレ一覧

### 6.1 認証フロー
- [ ] **OAuthログインボタン**: Figma仕様あり、実装なし
- [ ] **再認証モーダル**: 仕様あり、実装なし

### 6.2 ホーム画面
- [ ] **スター単位課金表示**: 仕様あり、実装なし（固定価格のみ）
- [ ] **年齢別推奨価格メッセージ**: 仕様あり、実装なし

### 6.3 ガチャ画面
- [ ] **広告視聴UI**: 部分実装、完全なフロー未実装
- [ ] **ガチャ結果アニメーション**: 基本実装のみ

### 6.4 スターデータ画面
- [ ] **タイムライン表示**: 基本実装、フィルター機能不足
- [ ] **カテゴリ別ビュー**: 基本実装、ソート機能不足

---

## 7. 🐛 今すぐ修正すべき優先度の高いバグ

### P0: クリティカル（即座に修正）

#### バグ1: ガチャRPC関数のパラメータ不足
- **場所**: 提供された`GachaRepository`コード
- **問題**: RPC関数呼び出しに必須パラメータ`target_user_id`が欠落
- **影響**: ガチャ機能が完全に動作しない
- **修正**: すべてのRPC呼び出しに`target_user_id`パラメータを追加

#### バグ2: テーブル名の不整合
- **場所**: `lib/src/features/gacha/data/gacha_limits_repository.dart`
- **問題**: 存在しない`gacha_attempts`テーブルを参照
- **影響**: ガチャ回数取得が失敗する
- **修正**: `gacha_daily_attempts`に統一

#### バグ3: RPC関数の戻り値型不一致
- **場所**: 提供された`GachaRepository`コード
- **問題**: `void`関数から`int`/`bool`を返そうとしている
- **影響**: 型エラーまたは予期しない動作
- **修正**: 戻り値型を`void`に変更

### P1: 高優先度（早期修正）

#### バグ4: 認証セッション切れ時のハンドリング不足
- **場所**: 全体的
- **問題**: 401/403エラー時の再認証フローなし
- **影響**: セッション切れ時にアプリが使用不能

#### バグ5: サブスクリプション更新通知未実装
- **場所**: `lib/src/features/subscription_service.dart`
- **問題**: 更新成功/失敗通知が未実装
- **影響**: ユーザーが更新状態を把握できない

#### バグ6: ダークテーマ未実装
- **場所**: `lib/theme/app_theme.dart`
- **問題**: ダークテーマがTODOのまま
- **影響**: ユーザー設定が反映されない

#### バグ7: プロフィール画像アップロード未実装
- **場所**: プロフィール編集画面
- **問題**: 画像アップロード機能が未実装
- **影響**: プロフィール画像設定ができない

#### バグ8: データ取り込み精度の問題
- **場所**: `lib/providers/youtube_history_provider.dart`
- **問題**: エンリッチメント、マッチスコア計算未実装
- **影響**: データ取り込みの精度が低い

---

## 8. 📝 MVPリリースに足りない項目リスト

### 🔴 P0: MVPリリース前に必須（ブロッカー）

#### 8.1 ガチャシステム完全実装
- [ ] **GachaRepositoryの修正**
  - RPC関数のパラメータ追加（`target_user_id`）
  - 戻り値型の修正（`void`関数の適切な処理）
  - テーブル名の統一（`gacha_daily_attempts`）

- [ ] **ガチャRPC関数の統合テスト**
  - `initialize_daily_gacha_attempts_jst3`の動作確認
  - `complete_ad_view_and_grant_ticket`の動作確認
  - `consume_gacha_attempt_atomic`の動作確認

#### 8.2 認証システム
- [ ] **OAuth連携実装**（Google/Apple）
  - `auth-sync` Edge Function呼び出し実装
  - OAuthフロー完全実装

- [ ] **再認証/401ハンドリング**
  - 401/403エラー検出
  - 再認証モーダル実装
  - セッション復旧フロー

#### 8.3 データベース整合性
- [ ] **古いスキーマの削除**
  - `gacha_attempts`テーブル削除（`gacha_daily_attempts`に統一）
  - 古いRPC関数の削除または新スキーマへの移行

- [ ] **マイグレーション整理**
  - 重複マイグレーションファイルの整理
  - スキーマバージョン管理の明確化

### 🟡 P1: リリース後早期対応（重要）

#### 8.4 課金・決済
- [ ] **決済フロー完全実装**
  - Stripe Webhook処理の完全実装
  - プラン変更・アップグレード機能
  - 決済失敗時のリトライ処理

- [ ] **通知システム統合**
  - サブスクリプション更新通知
  - 決済成功/失敗通知
  - 期限切れ通知

#### 8.5 UI/UX改善
- [ ] **ダークテーマ完全実装**
- [ ] **プロフィール画像アップロード**
- [ ] **タイムライン表示の完全実装**
- [ ] **エラーハンドリング強化**

#### 8.6 データ統合
- [ ] **データ取り込み精度向上**
  - エンリッチメント実装
  - マッチスコア計算実装
  - コンテンツモデレーション実装

- [ ] **Amazon購入履歴取込**
- [ ] **Netflix視聴履歴連携**

### 🟢 P2: 中優先度（機能拡張）

- [ ] コメント機能の高度化
- [ ] リアクションシステムの拡張
- [ ] 検索機能強化
- [ ] フィルタリング機能拡張

---

## 9. 📊 優先度マトリクス

| 優先度 | カテゴリ | 項目数 | 推定工数 |
|--------|---------|--------|----------|
| P0 | ガチャシステム修正 | 3 | 8時間 |
| P0 | 認証システム | 2 | 16時間 |
| P0 | DB整合性 | 2 | 4時間 |
| P1 | 課金・決済 | 3 | 12時間 |
| P1 | UI/UX改善 | 4 | 16時間 |
| P1 | データ統合 | 3 | 20時間 |
| P2 | 機能拡張 | 4 | 24時間 |

**合計推定工数**: 約100時間（2.5週間、1名フルタイム）

---

## 10. 🎯 推奨アクションプラン

### フェーズ1: 緊急修正（1週間）
1. ガチャRPC関数の修正（P0）
2. データベース整合性の確保（P0）
3. 認証システムの基本実装（P0）

### フェーズ2: MVP完成（2週間）
1. 課金・決済フローの完全実装（P1）
2. UI/UX改善（P1）
3. データ統合精度向上（P1）

### フェーズ3: リリース準備（1週間）
1. 統合テスト
2. パフォーマンス最適化
3. ドキュメント整備

---

## 11. 📚 参照ドキュメント

- `repository/Task.md`: タスク管理
- `docs/planning/STARLIST_未実装機能リスト.md`: 未実装機能一覧
- `docs/reports/DAY4_SOT_DIFFS.md`: 実装と仕様の差分
- `supabase/migrations/20250722100000_gacha_ads_jst3.sql`: ガチャスキーマ定義

---

**レポート作成日**: 2025-11-30  
**次回更新推奨日**: 修正完了後

