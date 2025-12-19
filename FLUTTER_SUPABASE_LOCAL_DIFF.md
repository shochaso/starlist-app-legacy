# Flutterアプリ側のSupabaseローカル環境設定変更

## 概要

FlutterアプリをローカルSupabase環境に接続するための設定変更です。

## 変更ファイル

### 1. `lib/config/environment_config.dart`

**変更内容**: デフォルト値をローカル環境に変更

```dart
// 変更前
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://zjwvmoxpacbpwawlwbrd.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);

// 変更後
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://localhost:54321',  // ローカル環境
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'hhZCOuXtaN69ZtpORFubZ5vZp6IBG5UvYmpK_8cap0E',  // .env.localのANON_KEY
);
```

## 実行方法

### 方法1: 環境変数で指定（推奨）

```bash
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=hhZCOuXtaN69ZtpORFubZ5vZp6IBG5UvYmpK_8cap0E
```

### 方法2: デフォルト値を変更

`lib/config/environment_config.dart` のデフォルト値を上記の通り変更してください。

## 注意事項

1. **iOS Simulator / Android Emulator**: 
   - iOS Simulator: `localhost` は `127.0.0.1` に変更が必要な場合があります
   - Android Emulator: `localhost` は `10.0.2.2` に変更が必要です

2. **実機デバイス**:
   - `localhost` は使用できません
   - 開発マシンのIPアドレスを使用してください（例: `http://192.168.1.100:54321`）

3. **ネットワーク設定**:
   - FlutterアプリとDockerコンテナが同じネットワーク上にあることを確認してください

## 検証方法

1. Supabase Studioにアクセス: http://localhost:54323
2. Flutterアプリを起動
3. ログイン機能をテスト
4. Intake APIをテスト



