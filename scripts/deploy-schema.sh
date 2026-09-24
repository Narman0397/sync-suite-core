#!/usr/bin/env bash
# BERBAHAYA: script ini MENGHAPUS schema public (DROP SCHEMA public CASCADE)
# lalu membangun ulang dari supabase/schema.sql + supabase/seed.sql.
#
# Hanya untuk bootstrap database kosong atau pemulihan darurat. Deploy harian
# memakai migrasi inkremental (`supabase db push`), bukan script ini.
#
# Gerbang: CONFIRM_RESET harus bernilai RESET-PRODUCTION.
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=scripts/lib-db.sh
source "$ROOT_DIR/scripts/lib-db.sh"

if [[ "${CONFIRM_RESET:-}" != "RESET-PRODUCTION" ]]; then
  echo "::error::Reset dibatalkan. Set CONFIRM_RESET=RESET-PRODUCTION untuk melanjutkan."
  exit 1
fi

SCHEMA_SQL="$ROOT_DIR/supabase/schema.sql"
SEED_SQL="$ROOT_DIR/supabase/seed.sql"
BUILD_SQL="${RUNNER_TEMP:-/tmp}/full-deploy.sql"
APPLY_SEED="${APPLY_SEED:-true}"

[[ -s "$SCHEMA_SQL" ]] || { echo "::error::supabase/schema.sql kosong/tidak ada"; exit 1; }

{
  cat <<'SQL'
BEGIN;
SET statement_timeout = 0;
SET client_min_messages = warning;
SET check_function_bodies = off;

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT CREATE ON SCHEMA public TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;

SQL

  sed -e '/^CREATE SCHEMA IF NOT EXISTS public;$/d' "$SCHEMA_SQL"

  if [[ "$APPLY_SEED" == "true" && -s "$SEED_SQL" ]]; then
    echo
    echo "-- ---------- SEED DATA ----------"
    cat "$SEED_SQL"
  fi

  cat <<'SQL'

-- Trigger auth -> profiles berada di luar schema public sehingga tidak ikut
-- dalam dump, tapi wajib dipasang ulang setelah public schema dibangun ulang.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
COMMIT;

-- PostgREST menyimpan schema cache; tanpa reload, tabel baru menghasilkan
-- PGRST205 "Could not find the table ... in the schema cache".
NOTIFY pgrst, 'reload schema';
SQL
} > "$BUILD_SQL"

echo "Generated deploy SQL: $(wc -l < "$BUILD_SQL") lines"

db_run -f "$BUILD_SQL"

# Setelah reset penuh, tandai semua migrasi sebagai sudah diterapkan supaya
# `supabase db push` berikutnya tidak mencoba mereplay baseline.
db_run <<'SQL'
CREATE SCHEMA IF NOT EXISTS supabase_migrations;
CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
  version text PRIMARY KEY,
  statements text[],
  name text
);
SQL

for f in "$ROOT_DIR"/supabase/migrations/*.sql; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  version="${base%%_*}"
  db_run -c "INSERT INTO supabase_migrations.schema_migrations(version, name) VALUES ('$version', '$base') ON CONFLICT (version) DO NOTHING;"
done

echo "Schema + seed berhasil diterapkan; riwayat migrasi disinkronkan."
