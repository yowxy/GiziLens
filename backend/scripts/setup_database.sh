#!/usr/bin/env bash
# ============================================================================
# GiziLens — bootstrap PostgreSQL + apply migrations (Linux/macOS/Git Bash)
# ============================================================================
# Requires psql on PATH. You will be prompted for the postgres password.
#
#   ./scripts/setup_database.sh
#   PGUSER=postgres PGHOST=localhost PGPORT=5432 ./scripts/setup_database.sh
# ============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

PGUSER="${PGUSER:-postgres}"
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"

read -r -s -p "Password untuk user ${PGUSER}: " PGPASSWORD
export PGPASSWORD
echo

echo "==> Membuat role/database (bila belum ada)..."
psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres \
  -v gizilens_password="gizilens" \
  -f scripts/setup_database.sql

echo "==> Menjalankan migrasi + seed..."
python scripts/init_db.py

echo "==> Selesai."
