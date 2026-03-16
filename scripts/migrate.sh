#!/usr/bin/env bash
# ============================================================
# migrate.sh — apply pending SQL migrations to Supabase
# ============================================================
# Prerequisites:  psql installed  (brew install postgresql)
# Usage:
#   export DATABASE_URL="postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"
#   ./scripts/migrate.sh
#
# Or pass it directly:
#   DATABASE_URL="..." ./scripts/migrate.sh
#
# Find DATABASE_URL in: Supabase dashboard → Project Settings → Database → Connection string (URI)
# ============================================================

set -euo pipefail

MIGRATIONS_DIR="$(cd "$(dirname "$0")/../migrations" && pwd)"

if [[ -z "${DATABASE_URL:-}" ]]; then
  # Try loading from .env in project root
  ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    set -a && source "$ENV_FILE" && set +a
  fi
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "❌  DATABASE_URL is not set."
  echo "    Export it or add it to .env in the project root."
  exit 1
fi

echo "🔌  Connecting to database..."
psql "$DATABASE_URL" -q -c "SELECT 1" > /dev/null 2>&1 || {
  echo "❌  Could not connect. Check DATABASE_URL."
  exit 1
}

# Ensure the migrations tracking table exists
psql "$DATABASE_URL" -q <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
  version     text        PRIMARY KEY,
  description text,
  applied_at  timestamptz DEFAULT now()
);
SQL

echo "📂  Scanning: $MIGRATIONS_DIR"
echo ""

applied=0
skipped=0

for filepath in "$MIGRATIONS_DIR"/*.sql; do
  [[ -f "$filepath" ]] || continue
  filename="$(basename "$filepath")"
  # Version is the leading number block, e.g. "0001" from "0001_create_app_schema.sql"
  version="${filename%%_*}"

  already_applied=$(psql "$DATABASE_URL" -t -q \
    -c "SELECT COUNT(*) FROM schema_migrations WHERE version = '$version';" \
    | tr -d ' \n')

  if [[ "$already_applied" -gt 0 ]]; then
    echo "  ⏭️   $filename  (already applied)"
    ((skipped++)) || true
  else
    echo "  ▶️   Applying $filename ..."
    psql "$DATABASE_URL" -q -f "$filepath"
    psql "$DATABASE_URL" -q \
      -c "INSERT INTO schema_migrations(version, description) VALUES('$version','$filename') ON CONFLICT DO NOTHING;"
    echo "  ✅  $filename applied"
    ((applied++)) || true
  fi
done

echo ""
echo "Done — $applied applied, $skipped skipped."
