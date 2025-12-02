#!/bin/bash
# Supabase Local環境の状態確認スクリプト

echo "🔍 Supabase Local Environment Status Check"
echo "=========================================="
echo ""

# Docker Desktop起動確認
echo "1️⃣ Docker Desktop:"
if docker info > /dev/null 2>&1; then
    echo "   ✅ Running"
    docker version --format "   Version: {{.Server.Version}}" 2>/dev/null || echo "   Version: (checking...)"
else
    echo "   ❌ Not running"
    echo "   → Please start Docker Desktop first"
    exit 1
fi
echo ""

# コンテナ状態確認
echo "2️⃣ Supabase Containers:"
if docker ps --filter "name=supabase" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -q supabase; then
    docker ps --filter "name=supabase" --format "   ✅ {{.Names}}: {{.Status}}"
else
    echo "   ⚠️  No Supabase containers running"
    echo "   → Run: ./check-docker-and-setup.sh"
fi
echo ""

# サービス接続確認
echo "3️⃣ Service Endpoints:"
echo "   API Gateway:"
if curl -s -o /dev/null -w "   %{http_code}" http://localhost:54321/rest/v1/ > /dev/null 2>&1; then
    echo "   ✅ http://localhost:54321 (accessible)"
else
    echo "   ❌ http://localhost:54321 (not accessible)"
fi

echo "   Studio:"
if curl -s -o /dev/null -w "   %{http_code}" http://localhost:54323 > /dev/null 2>&1; then
    echo "   ✅ http://localhost:54323 (accessible)"
else
    echo "   ❌ http://localhost:54323 (not accessible)"
fi

echo "   Edge Functions:"
if curl -s -o /dev/null -w "   %{http_code}" http://localhost:54321/functions/v1/intake -X POST -H "Content-Type: application/json" -d '{"ocrText":"__HEALTHCHECK__"}' > /dev/null 2>&1; then
    echo "   ✅ http://localhost:54321/functions/v1/intake (accessible)"
else
    echo "   ❌ http://localhost:54321/functions/v1/intake (not accessible)"
fi
echo ""

# データベース確認
echo "4️⃣ Database:"
if docker exec supabase_db_starlist pg_isready -U supabase_admin > /dev/null 2>&1; then
    echo "   ✅ PostgreSQL is ready"
else
    echo "   ❌ PostgreSQL is not ready"
fi
echo ""

echo "=========================================="
echo "✅ Status check complete!"
