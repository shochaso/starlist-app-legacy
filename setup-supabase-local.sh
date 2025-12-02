#!/bin/bash
# Supabase Local Development Environment Setup Script

set -e

echo "🚀 Setting up Supabase Local Development Environment..."

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo "❌ .env.local not found. Please create it first."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "📦 Starting Supabase services..."
# .env.localを明示的に読み込む（exportしてからdocker composeを実行）
set -a
source .env.local
set +a
docker compose -f docker-compose.supabase.yml up -d

echo "⏳ Waiting for services to be ready..."
sleep 10

# Wait for database to be ready
echo "🔍 Checking database connection..."
until docker exec supabase_db_starlist pg_isready -U supabase_admin > /dev/null 2>&1; do
    echo "   Waiting for database..."
    sleep 2
done

echo "✅ Database is ready!"

# Run migrations
echo "📊 Running database migrations..."
docker exec -i supabase_db_starlist psql -U supabase_admin -d postgres < supabase/migrations/20251128_intake_metrics.sql 2>/dev/null || echo "Migration may already exist"
docker exec -i supabase_db_starlist psql -U supabase_admin -d postgres < supabase/migrations/20251201_intake_metrics_views.sql 2>/dev/null || echo "Migration may already exist"

echo "✅ Migrations completed!"

echo ""
echo "🎉 Supabase Local Environment is ready!"
echo ""
echo "📍 Services:"
echo "   - API Gateway: http://localhost:54321"
echo "   - Studio: http://localhost:54323"
echo "   - Database: localhost:54322"
echo "   - Edge Functions: http://localhost:54321/functions/v1/"
echo ""
echo "🔑 Keys (from .env.local):"
echo "   - ANON_KEY: ${ANON_KEY:0:20}..."
echo "   - SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY:0:20}..."
echo ""
echo "🧪 Test Intake API:"
echo "   curl -X POST http://localhost:54321/functions/v1/intake \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"ocrText\": \"test\"}'"
echo ""
