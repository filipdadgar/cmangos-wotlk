#!/usr/bin/env bash
set -euo pipefail
# Runner entrypoint: apply DB env vars into config files and run command as 'mangos'
# Determine effective DB settings from Kubernetes env vars (preferred) or fallbacks
DB_HOST="${DATABASE_HOSTNAME:-${MANGOS_DBHOST:-localhost}}"
DB_PORT="${DATABASE_PORT:-${MANGOS_DBPORT:-3306}}"
DB_USER="${MYSQL_APP_USER:-${MANGOS_DBUSER:-mangos}}"
DB_PASS="${MYSQL_APP_PASSWORD:-${MANGOS_DBPASS:-}}"

# Determine config dir — prefer an explicit mount or dedicated conf dir and do NOT copy or merge .dist files
# If you want to mount configs from the host, set MANGOS_CONF_DIR or mount into /opt/mangos/conf
CONFIG_DIR=""
if [ -n "${MANGOS_CONF_DIR:-}" ]; then
  if [ -d "${MANGOS_CONF_DIR}" ]; then
    CONFIG_DIR="${MANGOS_CONF_DIR}"
  else
    echo "Warning: MANGOS_CONF_DIR='${MANGOS_CONF_DIR}' is set but does not exist; falling back to default search" >&2
  fi
fi

if [ -z "$CONFIG_DIR" ]; then
  POSSIBLE_ETC=(/opt/mangos/conf /opt/mangos/etc /cmangos/etc /opt/mangos)
  for d in "${POSSIBLE_ETC[@]}"; do
    if [ -d "$d" ]; then
      CONFIG_DIR="$d"
      break
    fi
  done
fi

# Fallback to a default directory if nothing exists
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="/opt/mangos/etc"
  mkdir -p "$CONFIG_DIR" || true
fi

# Note: do NOT copy .dist to .conf and do NOT merge external config files — we expect the user to mount the real config
if [ ! -f "$CONFIG_DIR/mangosd.conf" ] && [ -f "$CONFIG_DIR/mangosd.conf.dist" ]; then
  echo "Note: found mangosd.conf.dist in ${CONFIG_DIR} but will NOT copy it to mangosd.conf; mount your own mangosd.conf if needed" >&2
fi
if [ ! -f "$CONFIG_DIR/realmd.conf" ] && [ -f "$CONFIG_DIR/realmd.conf.dist" ]; then
  echo "Note: found realmd.conf.dist in ${CONFIG_DIR} but will NOT copy it to realmd.conf; mount your own realmd.conf if needed" >&2
fi

echo "Using config dir: ${CONFIG_DIR}"

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

# # Apply to mangosd.conf
# if [ -f "$CONFIG_DIR/mangosd.conf" ]; then
#   replace_db_line "$CONFIG_DIR/mangosd.conf" "LoginDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_REALMD_DBNAME:-realmd}"
#   replace_db_line "$CONFIG_DIR/mangosd.conf" "WorldDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_WORLD_DBNAME:-wotlkmangos}"
#   replace_db_line "$CONFIG_DIR/mangosd.conf" "CharacterDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_CHARACTERS_DBNAME:-wotlkcharacters}"
# fi

# # Apply to realmd.conf
# if [ -f "$CONFIG_DIR/realmd.conf" ]; then
#   replace_db_line "$CONFIG_DIR/realmd.conf" "LoginDatabaseInfo" "${DB_HOST};${DB_PORT};${DB_USER};${DB_PASS};${MANGOS_REALMD_DBNAME:-realmd}"
# fi

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

# # Wait for DB helper (pure bash using /dev/tcp)
# wait_for_database() {
#   local host="${DB_HOST}" port="${DB_PORT}" timeout="${DB_WAIT_TIMEOUT:-60}"
#   local start
#   start=$(date +%s)
#   echo "Waiting for database ${host}:${port} (timeout ${timeout}s)..."
#   while true; do
#     if bash -c "cat < /dev/tcp/${host}/${port}" >/dev/null 2>&1; then
#       echo "Database ${host}:${port} is reachable"
#       break
#     fi
#     if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
#       echo "Timeout while waiting for database ${host}:${port}" >&2
#       return 1
#     fi
#     sleep 1
#   done
# }

# Service runners
run_mangosd() {
  cd /opt/mangos/bin || true
  if command -v gosu >/dev/null 2>&1; then
    exec gosu mangos ./mangosd "$@"
  else
    exec ./mangosd "$@"
  fi
}

run_realmd() {
  cd /opt/mangos/bin || true
  if command -v gosu >/dev/null 2>&1; then
    exec gosu mangos ./realmd "$@"
  else
    exec ./realmd "$@"
  fi
}

# Dispatch by first arg: add DB wait for known services, otherwise exec arbitrary command
if [ "$#" -gt 0 ]; then
  case "$1" in
    mangosd)
      shift
#      wait_for_database || exit 1
      run_mangosd "$@"
      ;;
    realmd)
      shift
      wait_for_database || exit 1
      run_realmd "$@"
      ;;
    *)
      if command -v gosu >/dev/null 2>&1; then
        exec gosu mangos "$@"
      else
        exec "$@"
      fi
      ;;
  esac
fi

# If no args provided, print usage and exit
echo "No command provided; expected 'mangosd' or 'realmd' or another command" >&2
exit 1
