# Next.js / Tailwind / shadcn 診断レポート

**診断日**: 2025-11-30  
**診断対象**: Next.jsプロジェクト構成  
**診断者**: AI診断エンジニア

---

## 1. Next.js 構成診断

### ✅ 基本構成

#### package.json
- **Next.jsバージョン**: `^13.5.0` (App Router対応)
- **Reactバージョン**: `^18.3.0`
- **TypeScript**: `^5.3.3`
- **Node.js要件**: `>=20`

#### next.config.mjs
- **設定**: 最小構成
- **TypeScript設定**: `next-tsconfig.json`を参照
- **問題点**: 特に問題なし

#### next-tsconfig.json
- **設定**: Next.js用のTypeScript設定
- **パスエイリアス**: 
  - `@/components/*` → `./app/components/*`
  - `@/components/kpi/*` → `./app/components/kpi/*`
  - `@/types/*` → `./types/*`
- **問題点**: 特に問題なし

### ⚠️ 注意点

1. **Next.jsバージョン**: `13.5.0`は比較的古いバージョン
   - 最新は`14.x`系
   - App Routerは使用可能だが、最新機能は利用不可

2. **TypeScript設定**: 2つのtsconfig.jsonが存在
   - `tsconfig.json`: スクリプト用
   - `next-tsconfig.json`: Next.js用
   - これは正常な構成

---

## 2. Tailwind / shadcn 診断

### ✅ Tailwind CSS構成

#### tailwind.config.js
- **設定**: 基本構成
- **contentパス**: `./app/**/*.{ts,tsx}`, `./components/**/*.{ts,tsx}`
- **テーマ拡張**: なし（デフォルト）
- **プラグイン**: なし

#### globals.css
- **Tailwindディレクティブ**: 正しく設定
  - `@tailwind base;`
  - `@tailwind components;`
  - `@tailwind utilities;`
- **カスタムスタイル**: 
  - フォント: Inter, Noto Sans JP
  - 背景色: `bg-slate-950`
  - テキスト色: `text-slate-50`

#### postcss.config.js
- **設定**: 確認済み（存在）

### ❌ shadcn/ui 診断

#### 問題点

1. **shadcn/uiパッケージ未インストール**
   - `package.json`にshadcn/ui関連の依存関係が存在しない
   - 必要なパッケージ:
     - `@radix-ui/*` (UIプリミティブ)
     - `class-variance-authority` (CVA)
     - `clsx` (クラス名ユーティリティ)
     - `tailwind-merge` (Tailwindクラスマージ)

2. **UIコンポーネントの実装状況**
   - `app/components/ui/button.tsx`: **未完成**（Tailwindクラスなし）
   - `app/components/ui/card.tsx`: **未完成**（Tailwindクラスなし）
   - `app/components/ui/input.tsx`: 存在
   - `app/components/ui/separator.tsx`: 存在
   - **shadcn/uiの標準実装ではない**

3. **cn()ユーティリティ関数**
   - `lib/utils.ts`または`lib/cn.ts`が存在しない
   - shadcn/uiの標準的な`cn()`関数が未実装

4. **components.json**
   - shadcn/uiの設定ファイルが存在しない
   - 通常は`components.json`でコンポーネントのパスやスタイルを管理

### ⚠️ 現状

- **Tailwind CSS**: ✅ 正しく設定済み
- **shadcn/ui**: ❌ **未導入**（UIコンポーネントは存在するが、shadcn/uiの標準実装ではない）

---

## 3. ルーティング診断

### ✅ App Router構成

#### ルート構造
```
app/
├── page.tsx                    # ルート (/)
├── layout.tsx                  # ルートレイアウト
├── login/
│   └── page.tsx               # /login
├── dashboard/
│   └── audit/
│       └── page.tsx           # /dashboard/audit
├── star-data-preview/
│   └── page.tsx               # /star-data-preview
├── teaser/
│   └── page.tsx               # /teaser
└── api/
    ├── audit/
    │   └── latest/
    │       └── route.ts       # /api/audit/latest
    ├── youtube/
    │   ├── video/
    │   │   └── route.ts       # /api/youtube/video
    │   └── youtube-intake/
    │       └── route.ts       # /api/youtube-intake
```

### ✅ ルーティング評価

- **App Router**: 正しく使用されている
- **ルート構造**: 明確で整理されている
- **API Routes**: 正しく配置されている
- **問題点**: 特に問題なし

---

## 4. デザインテーマ診断（ブランドカラーの有無）

### ✅ 現在のテーマ設定

#### globals.css
- **背景色**: `bg-slate-950` (ダークテーマ)
- **テキスト色**: `text-slate-50` (ライトテキスト)
- **フォント**: Inter, Noto Sans JP

#### tailwind.config.js
- **テーマ拡張**: なし
- **カスタムカラー**: 定義されていない

### ❌ ブランドカラー未定義

1. **STARLISTブランドカラーが未定義**
   - SoTで指定された「白基調90% + グレー10% + アクセント1色（薄い水色）」が未実装
   - Tailwindのカスタムカラーとして定義されていない

2. **現在のテーマ**
   - ダークテーマ（`slate-950`）を使用
   - SoTの「白基調」と矛盾

3. **必要な設定**
   - `tailwind.config.js`にカスタムカラーを追加
   - CSS変数でのカラーパレット定義
   - テーマ切り替え機能（必要に応じて）

---

## 5. 実装前の注意点

### 🔴 必須対応事項

1. **shadcn/uiの導入**
   - `npx shadcn-ui@latest init`を実行
   - 必要なパッケージをインストール
   - `components.json`を設定`
   - `cn()`ユーティリティ関数を実装

2. **ブランドカラーの定義**
   - `tailwind.config.js`にカスタムカラーを追加
   - SoT準拠のカラーパレット:
     - 白基調: `#FFFFFF`
     - グレー: `#E9E9EC`
     - アクセント（薄い水色）: `#E8F4F8` / `#5E9DB8`

3. **UIコンポーネントの再実装**
   - 既存の`button.tsx`、`card.tsx`は未完成
   - shadcn/uiの標準コンポーネントを使用
   - SoT準拠のスタイルを適用

4. **テーマの統一**
   - 現在はダークテーマ（`slate-950`）
   - SoTは「白基調」を要求
   - テーマをライトテーマに変更

### ⚠️ 推奨対応事項

1. **Next.jsバージョンの更新**
   - `13.5.0` → `14.x`系への更新を検討
   - 最新機能の利用

2. **TypeScript設定の最適化**
   - パスエイリアスの整理
   - 型定義の強化

3. **コンポーネント構造の整理**
   - `app/components/ui/`の整理
   - shadcn/uiの標準構造に合わせる

---

## 6. 結論（UI実装が可能な状態か）

### ❌ **現状ではUI実装が困難**

#### 理由

1. **shadcn/uiが未導入**
   - UIコンポーネントの基盤が整っていない
   - 標準的なコンポーネントライブラリが使用できない

2. **ブランドカラーが未定義**
   - SoT準拠のカラーパレットが未実装
   - テーマがSoTと矛盾（ダーク vs 白基調）

3. **UIコンポーネントが未完成**
   - 既存のコンポーネントはTailwindクラスが適用されていない
   - 実用的なコンポーネントとして機能しない

### ✅ 実装可能にするための前提条件

1. **shadcn/uiの導入**（必須）
   ```bash
   npx shadcn-ui@latest init
   ```

2. **ブランドカラーの定義**（必須）
   - `tailwind.config.js`にカスタムカラーを追加
   - CSS変数でのカラーパレット定義

3. **テーマの変更**（必須）
   - ダークテーマからライトテーマ（白基調）へ変更

4. **UIコンポーネントの再実装**（必須）
   - shadcn/uiの標準コンポーネントを使用
   - SoT準拠のスタイルを適用

### 📊 実装準備度

| 項目 | 状態 | 準備度 |
|------|------|--------|
| Next.js構成 | ✅ 正常 | 100% |
| Tailwind CSS | ✅ 正常 | 100% |
| shadcn/ui | ❌ 未導入 | 0% |
| ブランドカラー | ❌ 未定義 | 0% |
| UIコンポーネント | ❌ 未完成 | 20% |
| **総合** | **❌ 未準備** | **44%** |

---

## 7. 次のステップ（実装前の準備）

### Step 1: shadcn/uiの導入
```bash
npx shadcn-ui@latest init
```

### Step 2: ブランドカラーの定義
- `tailwind.config.js`にカスタムカラーを追加
- CSS変数でのカラーパレット定義

### Step 3: テーマの変更
- `globals.css`を白基調に変更
- `layout.tsx`の背景色を変更

### Step 4: UIコンポーネントの実装
- shadcn/uiの標準コンポーネントを使用
- SoT準拠のスタイルを適用

---

**診断完了**: 2025-11-30  
**次のアクション**: 上記の前提条件を満たしてからUI実装を開始


