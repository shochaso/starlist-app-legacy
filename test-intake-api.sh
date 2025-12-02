#!/bin/bash
# Intake API Test Script

set -e

API_URL="http://localhost:54321/functions/v1/intake"
ANON_KEY="hhZCOuXtaN69ZtpORFubZ5vZp6IBG5UvYmpK_8cap0E"

echo "🧪 Testing Intake API..."
echo ""

# Test 1: Health Check
echo "1️⃣ Health Check Test"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{"ocrText": "__HEALTHCHECK__"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.' || echo "Response received"
echo ""

# Test 2: Normal Request
echo "2️⃣ Normal Request Test"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{"ocrText": "Test video title - Channel Name"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.' || echo "Response received"
echo ""

# Test 3: Rate Limit Test (6 requests in a row)
echo "3️⃣ Rate Limit Test (6 requests)"
for i in {1..6}; do
  echo "Request $i:"
  curl -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -d '{"ocrText": "Test"}' \
    -w "\nHTTP Status: %{http_code}\n" \
    -s | jq -r '.error // .version // "Response received"' || echo "Response received"
  echo ""
  sleep 1
done

echo "✅ Tests completed!"
