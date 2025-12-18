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
DB_HOST=${DATABASE_HOSTNAME:-"localhost"}
DB_PORT=${DATABASE_PORT:-"3306"}
DB_USER=${MYSQL_APP_USER:-"mangos"}
DB_PASS=${MYSQL_APP_PASSWORD:-"mangos"}
SERVER_IP=${SERVERIP:-"127.0.0.1"}

if [ -f "$CONFDIR/ahbot.conf" ]; then
    echo "$CONFDIR/ahbot.conf is being used"
    AHCONFIG="-a $CONFDIR/ahbot.conf"
fi

echo "Configuring Mangos..."
echo "DB Host: $DB_HOST"
echo "Server IP: $SERVER_IP"

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

# Start mangosd in background and exec realmd in foreground using absolute paths
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

"$MANGOSD_BIN" -c "$CONFDIR/mangosd.conf" > /var/log/wow/mangosd.log 2>&1 &
exec "$REALMD_BIN" -c "$CONFDIR/realmd.conf"
