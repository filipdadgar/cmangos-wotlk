#!/bin/bash

mysql_app_user="root"
mysql_app_password="mangos"
database_hostname="localhost"
database_port="3306"

function prepare_database {

# setup mangos database
echo "$(date) [INFO]: Launching initial database setup ..."
echo "$(date) [INFO]: Creating databases"

 
echo "creating db"
mysql -u"${mysql_app_user}" -p"${mysql_app_password}" -h "${database_hostname}" -P3306 < /cmangos/sql/db_create_mysql.sql
echo "done creating db"

echo "mangos.sql"
mysql -u"${mysql_app_user}" -p"${mysql_app_password}" -h "${database_hostname}" -P3306 wotlkmangos < /cmangos/sql/mangos.sql
echo "done mangos.sql"

echo "characters.sql"
mysql -u"${mysql_app_user}" -p"${mysql_app_password}" -h "${database_hostname}" -P3306 wotlkcharacters < /cmangos/sql/characters.sql
echo "done characters"
echo "realmd.sql"
mysql -u"${mysql_app_user}" -p"${mysql_app_password}" -h "${database_hostname}" -P3306 wotlkrealmd < /cmangos/sql/realmd.sql 
echo "done realm"


echo "executing fulldb.sh"

echo "----"

cd /wotlk-db && ./InstallFullDB.sh

#mysql -u"${mysql_app_user}" -p"${mysql_app_password}" -h "${database_hostname}" -P3306 wotlkmangos < /cmangos/sql/WoTLKDB_1_3_14015.sql

#echo "Updates are being applied"

#for sql_file in $(ls /mangos-wotlk/sql/base/dbc/original_data/*.sql); do mysql -uroot -p"${mysql_app_password}" --database=wotlkmangos < $sql_file ; done
#for sql_file in $(ls /mangos-wotlk/sql/base/dbc/cmangos_fixes/*.sql); do mysql -uroot -p"${mysql_app_password}" --database=wotlkmangos < $sql_file ; done
#for sql_file in $(ls /mangos-wotlk/sql/updates/mangos/*.sql); do mysql -uroot -p"${mysql_app_password}" --database=wotlkmangos < $sql_file ; done

#echo "done with updates.."


echo "done with db stuff"


}

function init {
prepare_database
}

init
