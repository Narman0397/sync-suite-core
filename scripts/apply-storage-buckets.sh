#!/usr/bin/env bash
# Buat semua bucket storage yang dibutuhkan aplikasi (idempotent).
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=scripts/lib-db.sh
source "$ROOT_DIR/scripts/lib-db.sh"

db_run -f "$ROOT_DIR/supabase/storage-buckets.sql"
echo "Bucket storage diterapkan."
