## 完了サマリ

* `starlist-app` のルート `/Users/shochaso/Downloads/starlist-app` を確認し、対象の 8 ファイルがすべて Git 未追跡（untracked）であることを確認。
* `git diff --no-index /dev/null ...` を用いて、8 ファイルすべての unified diff を取得し、`diff --git` 形式でレポート化した。
* これにより、Next.js 側の StarData ページ／ユーティリティ（TS/TSX）が「どのような状態で追加されているか」を把握できる土台が整った。

## 変更ファイル一覧（すべて未追跡）

* `app/stars/[username]/data/_components/DataPageShell.tsx`（新規）
* `app/stars/[username]/data/_components/PackSection.tsx`（新規）
* `app/stars/[username]/data/page.tsx`（新規）
* `lib/star-data/utils/normalizeDate.ts`（新規）
* `lib/star-data/utils/starIdResolver.ts`（新規）
* `lib/star-data/utils/buildPackId.ts`（新規）
* `lib/star-data/requests/rpcParams.ts`（新規）
* `lib/star-data/repository/supabaseStarDataRepository.ts`（新規）

## 今後の想定タスク（別Issueで管理推奨）

* これら 8 ファイルを正式にリポジトリへ取り込むかどうかの判断
  * Flutter 側の StarData 実装との役割分担を整理（LP/管理画面用なのか、本番 Web クライアントなのかなど）
* 必要であれば、型定義・API 契約・UI デザインを MVP 方針に合わせて最小限に整える
* 取り込み決定後は、ESLint/型エラーの解消と、簡易 E2E/スナップショットテストの整備

