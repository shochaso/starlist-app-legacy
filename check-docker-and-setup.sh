#!/bin/bash
# Docker Desktop起動確認とSupabaseセットアップスクリプト

set -e

echo "🔍 Checking Docker Desktop status..."

# Docker Desktop起動確認
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker Desktop is not running!"
    echo ""
    echo "📋 Please do the following:"
    echo "   1. Open Launchpad"
    echo "   2. Click 'Docker'"
    echo "   3. Wait for the 🐳 icon to appear in the menu bar (5-10 seconds)"
    echo "   4. Run this script again: ./check-docker-and-setup.sh"
    exit 1
fi

echo "✅ Docker Desktop is running"
echo ""

# .env.localのAPIキー確認
if grep -q "^GROQ_API_KEY=$" .env.local || grep -q "^YOUTUBE_API_KEY=$" .env.local; then
    echo "⚠️  API keys are empty in .env.local"
    echo "   Setting dummy keys..."
    sed -i '' 's/^GROQ_API_KEY=$/GROQ_API_KEY=dummy/' .env.local
    sed -i '' 's/^YOUTUBE_API_KEY=$/YOUTUBE_API_KEY=dummy/' .env.local
    echo "✅ Dummy keys set"
    echo ""
fi

echo "🚀 Starting Supabase local environment..."
./setup-supabase-local.sh
