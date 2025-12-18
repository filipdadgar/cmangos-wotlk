#!/usr/bin/env bash
set -euo pipefail
# Runner entrypoint: apply DB env vars into config files and run command as 'mangos'
# Determine effective DB settings from Kubernetes env vars (preferred) or fallbacks
DB_HOST="${DATABASE_HOSTNAME:-${MANGOS_DBHOST:-localhost}}"
DB_PORT="${DATABASE_PORT:-${MANGOS_DBPORT:-3306}}"
DB_USER="${MYSQL_APP_USER:-${MANGOS_DBUSER:-mangos}}"
DB_PASS="${MYSQL_APP_PASSWORD:-${MANGOS_DBPASS:-}}"

# Possible config locations used by different deployments
POSSIBLE_ETC=(/opt/mangos/etc /cmangos/etc /opt/mangos)
CONFIG_DIR=""
for d in "${POSSIBLE_ETC[@]}"; do
  if [ -d "$d" ]; then
    CONFIG_DIR="$d"
    break
  fi
done

if [ -z "$CONFIG_DIR" ]; then
  # fallback to /opt/mangos/etc inside image
  CONFIG_DIR="/opt/mangos/etc"
  mkdir -p "$CONFIG_DIR" || true
fi

# Ensure conf files exist (copy .dist if present)
[ -f "$CONFIG_DIR/mangosd.conf.dist" ] && [ ! -f "$CONFIG_DIR/mangosd.conf" ] && cp "$CONFIG_DIR/mangosd.conf.dist" "$CONFIG_DIR/mangosd.conf" || true
[ -f "$CONFIG_DIR/realmd.conf.dist" ] && [ ! -f "$CONFIG_DIR/realmd.conf" ] && cp "$CONFIG_DIR/realmd.conf.dist" "$CONFIG_DIR/realmd.conf" || true

# Helper to replace or append a DB info line
replace_db_line() {
  local file="$1"; shift
  local key="$1"; shift
  local value="$1"; shift
  if grep -q "^${key}" "$file" 2>/dev/null; then
    sed -i -E "s|^${key}.*|${key} = ${value}|" "$file" || true
  else
    echo "${key} = ${value}" >> "$file"
  fi
}

# Apply to mangosd.conf
if [ -f "$CONFIG_DIR/mangosd.conf" ]; then
  replace_db_line "$CONFIG_DIR/mangosd.conf" "LoginDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_REALMD_DBNAME:-realmd}"
  replace_db_line "$CONFIG_DIR/mangosd.conf" "WorldDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_WORLD_DBNAME:-wotlkmangos}"
  replace_db_line "$CONFIG_DIR/mangosd.conf" "CharacterDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_CHARACTERS_DBNAME:-wotlkcharacters}"
fi

# Apply to realmd.conf
if [ -f "$CONFIG_DIR/realmd.conf" ]; then
  replace_db_line "$CONFIG_DIR/realmd.conf" "LoginDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_REALMD_DBNAME:-realmd}"
fi

# Change into working dir if present
if [ -d "/opt/mangos" ]; then
  cd /opt/mangos || true
fi

# Ensure run-* wrapper scripts in bin are executable and owned by mangos (we're still root)
if [ -d "/opt/mangos/bin" ]; then
  for f in /opt/mangos/bin/run-*; do
    if [ -f "$f" ]; then
      chmod +x "$f" 2>/dev/null || true
      chown mangos:mangos "$f" 2>/dev/null || true
    fi
  done
fi

# Run as mangos user if possible
if command -v gosu >/dev/null 2>&1; then
  exec gosu mangos "$@"
else
  exec "$@"
fi
