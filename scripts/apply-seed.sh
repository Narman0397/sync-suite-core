#!/usr/bin/env bash
# Terapkan data referensi (supabase/seed.sql). Seed ditulis idempotent
# (ON CONFLICT DO NOTHING) sehingga aman dijalankan berulang.
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=scripts/lib-db.sh
source "$ROOT_DIR/scripts/lib-db.sh"

SEED_SQL="$ROOT_DIR/supabase/seed.sql"
if [[ ! -s "$SEED_SQL" ]]; then
  echo "supabase/seed.sql kosong/tidak ada — dilewati."
  exit 0
fi

db_run -f "$SEED_SQL"
db_run -c "NOTIFY pgrst, 'reload schema';"
echo "Seed diterapkan."
