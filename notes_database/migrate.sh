#!/bin/bash
set -euo pipefail

# Minimal migration runner for this container.
# - Reads connection string from db_connection.txt (required by container rules)
# - Applies *.sql files in migrations/ in lexicographic order
# - Records applied migrations in schema_migrations table

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN_STR="$(cat "${ROOT_DIR}/db_connection.txt")"

MIGRATIONS_DIR="${ROOT_DIR}/migrations"

if [ ! -d "${MIGRATIONS_DIR}" ]; then
  echo "No migrations directory found at ${MIGRATIONS_DIR}; skipping."
  exit 0
fi

echo "Ensuring schema_migrations table exists..."
${CONN_STR} -c "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"

echo "Applying migrations from ${MIGRATIONS_DIR} ..."
for f in $(ls -1 "${MIGRATIONS_DIR}"/*.sql 2>/dev/null | sort); do
  version="$(basename "${f}")"
  applied="$(${CONN_STR} -tA -c "SELECT 1 FROM schema_migrations WHERE version='${version}' LIMIT 1;")"
  if [ "${applied}" = "1" ]; then
    echo "✓ Skipping already-applied migration: ${version}"
    continue
  fi

  echo "→ Applying migration: ${version}"
  # Run the migration file
  ${CONN_STR} -v ON_ERROR_STOP=1 -f "${f}"
  # Record migration as applied
  ${CONN_STR} -v ON_ERROR_STOP=1 -c "INSERT INTO schema_migrations (version) VALUES ('${version}') ON CONFLICT DO NOTHING;"
  echo "✓ Applied migration: ${version}"
done

echo "Migrations complete."
