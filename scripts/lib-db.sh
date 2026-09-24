#!/usr/bin/env bash
# Helper koneksi database bersama untuk semua script deploy.
# Wajib: SUPABASE_PROJECT_ID, SUPABASE_DB_PASSWORD.
set -euo pipefail

: "${SUPABASE_PROJECT_ID:?SUPABASE_PROJECT_ID wajib diisi}"
: "${SUPABASE_DB_PASSWORD:?SUPABASE_DB_PASSWORD wajib diisi}"

export PGPASSWORD="$SUPABASE_DB_PASSWORD"

DB_POOLER_HOST="${SUPABASE_DB_HOST:-aws-0-us-east-1.pooler.supabase.com}"
DB_POOLER_USER="postgres.$SUPABASE_PROJECT_ID"
DB_DIRECT_HOST="db.$SUPABASE_PROJECT_ID.supabase.co"

# db_run <psql-args...> — coba pooler dulu, fallback ke direct host.
db_run() {
  if psql -v ON_ERROR_STOP=1 -X -q \
    "postgresql://$DB_POOLER_USER@$DB_POOLER_HOST:5432/postgres?sslmode=require" "$@"; then
    return 0
  fi
  echo "::warning::Koneksi pooler gagal, mencoba direct host."
  psql -v ON_ERROR_STOP=1 -X -q \
    "postgresql://postgres@$DB_DIRECT_HOST:5432/postgres?sslmode=require" "$@"
}
