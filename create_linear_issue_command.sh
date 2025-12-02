#!/bin/bash
# Linear Issue作成用コマンド
# 使用方法: 
#   1. LINEAR_API_KEY環境変数を設定
#   2. このスクリプトを実行

cd "$(dirname "$0")"

if [ -z "$LINEAR_API_KEY" ]; then
  echo "❌ ERROR: LINEAR_API_KEY環境変数が設定されていません"
  echo ""
  echo "設定方法:"
  echo "  export LINEAR_API_KEY='lin_api_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'"
  echo ""
  echo "Linear API Keyの取得方法:"
  echo "  1. https://linear.app にログイン"
  echo "  2. Settings → API → Personal API keys"
  echo "  3. Create new key をクリック"
  echo "  4. 生成されたキーをコピー"
  exit 1
fi

# 説明文を読み込む
DESCRIPTION=$(cat linear_issue_description.md)

# 環境変数として設定して実行
export LINEAR_ISSUE_TITLE="Next.js Star Data UI 用の未追跡ファイル8件の差分取得（状態整理）"
export LINEAR_ISSUE_DESCRIPTION="$DESCRIPTION"

npm run linear:create-issue

