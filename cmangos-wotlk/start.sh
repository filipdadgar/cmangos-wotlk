#!/bin/bash

# Try to detect installation layout used in the image or mounts.
# Prefer /opt/mangos, fall back to /cmangos, then to relative ./bin ./etc
if [ -n "${BINDIR:-}" ] && [ -d "$BINDIR" ]; then
    true
else
    if [ -d /opt/mangos/bin ]; then
        BINDIR=/opt/mangos/bin
    elif [ -d /cmangos/bin ]; then
        BINDIR=/cmangos/bin
    elif [ -d ./bin ]; then
        BINDIR=./bin
    else
        BINDIR="/opt/mangos/bin"
    fi
fi

if [ -n "${CONFDIR:-}" ] && [ -d "$CONFDIR" ]; then
    true
else
    if [ -d /opt/mangos/etc ]; then
        CONFDIR=/opt/mangos/etc
    elif [ -d /cmangos/etc ]; then
        CONFDIR=/cmangos/etc
    elif [ -d ./etc ]; then
        CONFDIR=./etc
    else
        CONFDIR="/opt/mangos/etc"
    fi
fi

# Default values if env vars are not set
DB_HOST=${DATABASE_HOSTNAME:-"mangos-mysql.dadgar.se"}
DB_PORT=${DATABASE_PORT:-"3306"}
DB_USER=${MYSQL_APP_USER:-"mangos"}
DB_PASS=${MYSQL_APP_PASSWORD:-"mangos"}
SERVER_IP=${SERVERIP:-"mangos.dadgar.se"}

if [ -f "$CONFDIR/ahbot.conf" ]; then
    echo "$CONFDIR/ahbot.conf is being used"
    AHCONFIG="-a $CONFDIR/ahbot.conf"
fi

echo "Configuring Mangos..."
echo "DB Host: $DB_HOST"
echo "Server IP: $SERVER_IP"

# If the config directory is not writable (e.g. mounted from ConfigMap),
# copy it to a writable location under the mangos home and use that copy.
ensure_writable_confdir()
{
    # prefer HOME or fallback
    TARGET_BASE="${HOME:-/home/mangos}"
    TARGET_DIR="$TARGET_BASE/mangos-etc"

    # quick test: can we create a temporary file in the config dir?
    if touch "$CONFDIR/.mangos_write_test" 2>/dev/null; then
        rm -f "$CONFDIR/.mangos_write_test" 2>/dev/null || true
        return 0
    fi

    echo "Config dir $CONFDIR is not writable; copying to $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    # copy files (preserve modes where possible) into writable dir
    cp -a "$CONFDIR/." "$TARGET_DIR/" 2>/dev/null || {
        echo "Warning: failed to copy configs from $CONFDIR to $TARGET_DIR" >&2
        return 1
    }
    CONFDIR="$TARGET_DIR"
    echo "Using writable config directory: $CONFDIR"
    return 0
}

# Ensure we have a writable config directory before modifying files
ensure_writable_confdir || true

# --- Database Configuration ---

# Update mangosd.conf connection strings
# Format: "Hostname;Port;User;Password;Database"
sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo     = \"$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;wotlkrealmd\"/" $CONFDIR/mangosd.conf
sed -i "s/^WorldDatabaseInfo.*/WorldDatabaseInfo     = \"$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;wotlkmangos\"/" $CONFDIR/mangosd.conf
sed -i "s/^CharacterDatabaseInfo.*/CharacterDatabaseInfo = \"$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;wotlkcharacters\"/" $CONFDIR/mangosd.conf

# Update realmd.conf connection string
sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo     = \"$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;wotlkrealmd\"/" $CONFDIR/realmd.conf

# --- Server Network Configuration ---

# Set the address the Realm Server advertises to clients
sed -i "s/^Address.*/Address = $SERVER_IP/" $CONFDIR/realmd.conf

# Ensure mangosd binds to all interfaces in the container (so it's reachable)
# If BindIP is set to 127.0.0.1 in the dist file, we change it to 0.0.0.0
sed -i "s/^BindIP.*/BindIP = 0.0.0.0/" $CONFDIR/mangosd.conf

# --- Game Settings ---

if [ -n "$STARTLEVEL" ]; then
    echo "Setting StartLevel to $STARTLEVEL"
    sed -i "s/^StartPlayerLevel.*/StartPlayerLevel = $STARTLEVEL/" $CONFDIR/mangosd.conf
fi

if [ -n "$MONEY" ]; then
    echo "Setting StartMoney to $MONEY"
    sed -i "s/^StartPlayerMoney.*/StartPlayerMoney = $MONEY/" $CONFDIR/mangosd.conf
fi

if [ -n "$SKIPCIN" ]; then
    echo "Setting SkipCinematics to $SKIPCIN"
    sed -i "s/^SkipCinematics.*/SkipCinematics = $SKIPCIN/" $CONFDIR/mangosd.conf
fi

echo "Starting mangosd and realmd..."
# Ensure log directory exists
mkdir -p /var/log/wow

# Start mangosd inside a named screen session so operators can attach:
#   screen -ls
#   screen -r mangos
# We start mangosd detached in session 'mangos' and keep realmd in foreground.
MANGOSD_BIN="$BINDIR/mangosd"
REALMD_BIN="$BINDIR/realmd"

if [ ! -x "$MANGOSD_BIN" ]; then
    echo "ERROR: mangosd not found or not executable at $MANGOSD_BIN"
    ls -l "$BINDIR" || true
    exit 1
fi
if [ ! -x "$REALMD_BIN" ]; then
    echo "ERROR: realmd not found or not executable at $REALMD_BIN"
    ls -l "$BINDIR" || true
    exit 1
fi

# Start mangosd and realmd inside monitored screen sessions (self-contained restart loops)
start_with_screen_loop() {
    local bin="$1"; shift
    local conf="$1"; shift
    local log="$1"; shift
    local session="$1"; shift

    if command -v screen >/dev/null 2>&1; then
        echo "Starting $bin under screen session '$session'"
        # remove stale session
        screen -S "$session" -X quit >/dev/null 2>&1 || true
        # build a small loop that restarts the daemon on non-zero exit and rotates logs
        screen -S "$session" -dm bash -lc '
            while true; do
                echo "$(date) [INFO] starting '""'""'${bin##*/}'""'""'" >> "$log" 2>&1
                "'$bin'" -c "'$conf'" >> "$log" 2>&1 || true
                rc=$?
                echo "$(date) [INFO] $bin exited with code $rc" >> "$log" 2>&1
                if [ "$rc" -eq 0 ]; then
                    break
                fi
                sleep 1
            done'
    else
        echo "screen not available; starting $bin directly in background"
        "$bin" -c "$conf" >> "$log" 2>&1 &
    fi
}

# Start mangosd and realmd using loops which will survive crashes and restart
start_with_screen_loop "$MANGOSD_BIN" "$CONFDIR/mangosd.conf" /var/log/wow/mangosd.log run-mangosd
start_with_screen_loop "$REALMD_BIN" "$CONFDIR/realmd.conf" /var/log/wow/realmd.log run-realmd

echo "Launched both services (detached). Tailing logs to keep container alive"
touch /var/log/wow/mangosd.log /var/log/wow/realmd.log
tail -F /var/log/wow/mangosd.log /var/log/wow/realmd.log
