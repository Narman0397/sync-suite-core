#!/usr/bin/env bash
# Jalankan E2E push delivery test dari sandbox.
# Usage:
#   TARGET_URL=https://narmantest99.lovable.app \
#   SUPABASE_URL=... EMAIL=... PASSWORD=... \
#   scripts/run-push-e2e.sh
#
# Login ke Supabase pakai password grant → dapat bearer super_admin → POST orchestrator.
set -euo pipefail
: "${TARGET_URL:?TARGET_URL required}"
: "${SUPABASE_URL:?SUPABASE_URL required}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY required}"
: "${EMAIL:?EMAIL required}"
: "${PASSWORD:?PASSWORD required}"

TOKEN=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_PUBLISHABLE_KEY" -H "content-type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | \
  python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

echo "→ POST $TARGET_URL/api/public/test/push-e2e"
curl -sS -X POST "$TARGET_URL/api/public/test/push-e2e" \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" -d "{}" \
  | python3 -m json.tool
