#!/usr/bin/env bash
# Verifikasi ringan setelah deploy: pastikan schema public terisi dan
# tabel inti ada. Gagal keras bila database kosong/rusak.
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=scripts/lib-db.sh
source "$ROOT_DIR/scripts/lib-db.sh"

REQUIRED_TABLES=(profiles user_roles opd desa layanan_publik permohonan forms)

read -r TABLES POLICIES FUNCS < <(
  db_run -At -F' ' -c "
    SELECT
      (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
      (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
      (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public');
  "
)

echo "Tabel public: $TABLES | RLS policies: $POLICIES | functions: $FUNCS"

if [[ "$TABLES" -lt 100 ]]; then
  echo "::error::Hanya $TABLES tabel di schema public — deploy tampaknya tidak lengkap."
  exit 1
fi

for t in "${REQUIRED_TABLES[@]}"; do
  exists=$(db_run -At -c "SELECT to_regclass('public.$t') IS NOT NULL;")
  if [[ "$exists" != "t" ]]; then
    echo "::error::Tabel wajib public.$t tidak ditemukan."
    exit 1
  fi
done

echo "Verifikasi schema OK."
