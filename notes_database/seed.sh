#!/bin/bash
set -euo pipefail

# Minimal seed runner for this container.
# - Reads connection string from db_connection.txt
# - Applies *.sql files in seeds/ in lexicographic order
# - Records applied seeds in schema_seeds table

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN_STR="$(cat "${ROOT_DIR}/db_connection.txt")"

SEEDS_DIR="${ROOT_DIR}/seeds"

if [ ! -d "${SEEDS_DIR}" ]; then
  echo "No seeds directory found at ${SEEDS_DIR}; skipping."
  exit 0
fi

echo "Ensuring schema_seeds table exists..."
${CONN_STR} -c "CREATE TABLE IF NOT EXISTS schema_seeds (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"

echo "Applying seeds from ${SEEDS_DIR} ..."
for f in $(ls -1 "${SEEDS_DIR}"/*.sql 2>/dev/null | sort); do
  version="$(basename "${f}")"
  applied="$(${CONN_STR} -tA -c "SELECT 1 FROM schema_seeds WHERE version='${version}' LIMIT 1;")"
  if [ "${applied}" = "1" ]; then
    echo "✓ Skipping already-applied seed: ${version}"
    continue
  fi

  echo "→ Applying seed: ${version}"
  ${CONN_STR} -v ON_ERROR_STOP=1 -f "${f}"
  ${CONN_STR} -v ON_ERROR_STOP=1 -c "INSERT INTO schema_seeds (version) VALUES ('${version}') ON CONFLICT DO NOTHING;"
  echo "✓ Applied seed: ${version}"
done

echo "Seeding complete."
