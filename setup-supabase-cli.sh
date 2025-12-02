#!/bin/bash
# Supabase CLI Local Development Environment Setup Script

set -e

echo "🚀 Setting up Supabase Local Development Environment (CLI method)..."

# Check if Supabase CLI is installed
if ! command -v supabase > /dev/null 2>&1; then
    echo "❌ Supabase CLI is not installed."
    echo "   Install: brew install supabase/tap/supabase"
    exit 1
fi

# Initialize Supabase if not already initialized
if [ ! -f supabase/config.toml ]; then
    echo "📝 Initializing Supabase project..."
    supabase init
fi

# Start Supabase
echo "📦 Starting Supabase services..."
supabase start

echo ""
echo "🎉 Supabase Local Environment is ready!"
echo ""
echo "📍 Services:"
supabase status
echo ""
echo "🧪 Test Intake API:"
echo "   curl -X POST \$(supabase status | grep 'API URL' | awk '{print \$3}')/functions/v1/intake \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"ocrText\": \"test\"}'"
echo ""
