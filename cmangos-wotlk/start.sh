#!/bin/bash

BINDIR=/cmangos/bin
CONFDIR=/cmangos/etc


if [ -f $CONFDIR/ahbot.conf ]; then
  echo "$CONFDIR/ahbot.conf is being used"
  AHCONFIG="-a $CONFDIR/ahbot.conf"
fi

# Fix ip for mangos and realm
sed -i "s/127.0.0.1/$SERVERIP/g" $CONFDIR/mangosd.conf
sed -i "s/127.0.0.1/$SERVERIP/g" $CONFDIR/realmd.conf

# Set mangos variables directly in file
#sed -i "s/StartPlayerLevel = 1/StartPlayerLevel = $STARTLEVEL/g" $CONFDIR/mangosd.conf
#echo "money"
#sed -i "s/StartPlayerMoney = 0/StartPlayerMoney = $MONEY/g" $CONFDIR/mangosd.conf
#echo "cinematics"
#sed -i "s/SkipCinematics = 0/SkipCinematics = $SKIPCIN/g" $CONFDIR/mangosd.conf



bash -c "screen -dmS mangos ./mangosd -c /cmangos/etc/mangosd.conf" && \
    ./realmd -c /cmangos/etc/realmd.conf
