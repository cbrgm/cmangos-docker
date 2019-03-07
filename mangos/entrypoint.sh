#!/bin/bash
echo "cbrgm/cmangos written by Christian Bargmann (c) 2019"
echo "https://cbrgm.net/"
echo ""
echo "Initializing docker container..."

setup_init () {
    setup_mysql_config
    setup_config
}

check_database_exists () {
    RESULT=`mysqlshow --user=${MYSQL_USER} --password=${MYSQL_PWD} --host=${MYSQL_HOST} ${MYSQL_DATABASE_WORLD} | grep -v Wildcard | grep -o ${MYSQL_DATABASE_WORLD} | tail -n 1`
    if [ "$RESULT" == "${MYSQL_DATABASE_WORLD}" ]; then
        return 0;
    else
        return 1;
    fi
}

setup_mysql_config () {
    echo "###### MySQL config setup ######"
    if [ -z "${MYSQL_HOST}" ]; then echo "Missing MYSQL_HOST environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_USER}" ]; then echo "Missing MYSQL_USER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_PWD}" ]; then echo "Missing MYSQL_PWD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_MANGOS_USER}" ]; then echo "Missing MYSQL_MANGOS_USER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_MANGOS_PWD}" ]; then echo "Missing MYSQL_MANGOS_PWD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_CHARACTER}" ]; then echo "Missing MYSQL_DATABASE_CHARACTER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_REALM}" ]; then echo "Missing MYSQL_DATABASE_REALM environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_WORLD}" ]; then echo "Missing MYSQL_DATABASE_WORLD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MANGOS_REALM_NAME}" ]; then echo "Missing MANGOS_REALM_NAME environment variable. Unable to continue."; exit 1; fi

    echo "Checking if databases already exists..."
    if  ! check_database_exists; then
        echo "Setting up MySQL config..."

        # Clone latest wotlk-db into database folder
        echo "Cloning latest database files..."
        git clone https://github.com/cmangos/mangos-wotlk -b master --recursive mangos
        git clone https://github.com/cmangos/wotlk-db -b master --recursive mangos/db

        echo "[STEP 1/6] General database setup"
        echo "Creating databases..."

cat > mangos/sql/create/db_create_mysql.sql <<EOF
CREATE DATABASE wotlkmangos DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE wotlkcharacters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE wotlkrealmd DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_MANGOS_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MANGOS_PWD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkmangos.* TO '${MYSQL_MANGOS_USER}'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkcharacters.* TO '${MYSQL_MANGOS_USER}'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkrealmd.* TO '${MYSQL_MANGOS_USER}'@'localhost';
CREATE USER IF NOT EXISTS '${MYSQL_MANGOS_USER}'@'%' IDENTIFIED BY '${MYSQL_MANGOS_PWD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkmangos.* TO '${MYSQL_MANGOS_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkcharacters.* TO '${MYSQL_MANGOS_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON wotlkrealmd.* TO '${MYSQL_MANGOS_USER}'@'%';
FLUSH PRIVILEGES;
EOF

        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} < mangos/sql/create/db_create_mysql.sql

        echo "[STEP 2/6] World database setup"
        echo "Initialize mangos database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/mangos.sql

        echo "Initialize dbc data..."

        cat mangos/sql/base/dbc/original_data/*.sql > mangos/sql/base/dbc/original_data/import.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/dbc/original_data/import.sql

        # Already covered by db install helper?
        # cat mangos/sql/base/dbc/cmangos_fixes/*.sql > mangos/sql/base/dbc/cmangos_fixes/import.sql
        # mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < mangos/sql/base/dbc/cmangos_fixes/import.sql

        echo "[STEP 3/6] Characters database setup"
        echo "Initialize characters database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_CHARACTER} < mangos/sql/base/characters.sql

        echo "[STEP 4/6] Realmd database setup"
        echo "Initialize realmd database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} < mangos/sql/base/realmd.sql

        echo "[STEP 5/6] Filling world database"
        echo "Filling up world database..."
        cd mangos/db
cat << EOF > InstallFullDB.config
DB_HOST="${MYSQL_HOST}"
DB_PORT="${MYSQL_PORT}"
DATABASE="${MYSQL_DATABASE_WORLD}"
USERNAME="${MYSQL_MANGOS_USER}"
PASSWORD="${MYSQL_MANGOS_PWD}"
CORE_PATH="/opt/mangos/mangos"
MYSQL="mysql"
FORCE_WAIT="NO"
DEV_UPDATES="NO"
EOF
        chmod a+x InstallFullDB.sh
        ./InstallFullDB.sh
        cd ../..

        echo "[STEP 6/6] Configure realmlist and gamemaster accounts"
        # Adding entry to realmlist
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "DELETE FROM realmlist WHERE id=1;"
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel) VALUES ('1', '${MANGOS_REALM_NAME}', '${MANGOS_SERVER_PUBLIC_IP}', '8085', '1', '0', '1', '0');"

        # Deleting all example entries from accounts db
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "TRUNCATE account;"

        # Add gamemaster account
        if ! [ -z "${MANGOS_GM_ACCOUNT}" ] && ! [ -z "${MANGOS_GM_PWD}" ]; then
            mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "INSERT INTO account (username,sha_pass_hash,gmlevel,expansion) VALUES ('${MANGOS_GM_ACCOUNT}', SHA1(CONCAT(UPPER('${MANGOS_GM_ACCOUNT}'),':',UPPER('${MANGOS_GM_PWD}'))),'4','2');"
        fi

        # Cleanup
        rm -rf /opt/mangos/mangos
    fi
}

setup_config() {
  echo "Mangos config setup..."

  # /opt/mangos/etc/mangosd.conf configuration
  echo "Configuring /opt/mangos/etc/mangosd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^WorldDatabaseInfo.*/WorldDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_WORLD}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^CharacterDatabaseInfo.*/CharacterDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_CHARACTER}/" /opt/mangos/etc/mangosd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/etc/mangosd.conf
  sed -i 's/^DataDir.*/DataDir = ".."/' /opt/mangos/etc/mangosd.conf

  # opt/mangos/etc/realmd.conf configuration
  echo "Configuring /opt/mangos/conf/realmd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_MANGOS_USER};${MYSQL_MANGOS_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/etc/realmd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/etc/realmd.conf

  # opt/mangos/etc/playerbot.conf configuration
  echo "Configuring /opt/mangos/etc/playerbot.conf..."
  sed -i "s/^PlayerbotAI.DisableBots.*/PlayerbotAI.DisableBots = ${MANGOS_ALLOW_PLAYERBOTS}/" /opt/mangos/etc/playerbot.conf
  sed -i "s/^PlayerbotAI.FollowDistanceMin.*/PlayerbotAI.FollowDistanceMin = 1/" /opt/mangos/etc/playerbot.conf
  sed -i "s/^PlayerbotAI.FollowDistanceMax.*/PlayerbotAI.FollowDistanceMax = 2/" /opt/mangos/etc/playerbot.conf

  # opt/mangos/etc/ahconf.conf configuration
  echo "Configuring /opt/mangos/etc/ahconf.conf..."
  sed -i "s/^AuctionHouseBot.Seller.Enabled.*/AuctionHouseBot.Seller.Enabled = ${MANGOS_ALLOW_AUCTIONBOT_SELLER}/" /opt/mangos/etc/ahbot.conf
  sed -i "s/^AuctionHouseBot.Buyer.Enabled.*/AuctionHouseBot.Buyer.Enabled = ${MANGOS_ALLOW_AUCTIONBOT_BUYER}/" /opt/mangos/etc/ahbot.conf

  # Gameplay specific options...
  if ! [ -z "${MANGOS_GAMETYPE}" ]; then sed -i "s/^GameType.*/GameType = ${MANGOS_GAMETYPE}/" /opt/mangos/etc/mangosd.conf; fi
  if ! [ -z "${MANGOS_MOTD}" ]; then sed -i "s/^Motd.*/Motd = ${MANGOS_MOTD}"/ /opt/mangos/etc/mangosd.conf; fi
}

sleep 10

# Download mangosd config from external url if set
# else use default env vars
if ! [ -z ${MANGOS_OVERRIDE_CONF_URL} ]; then
  echo "Downloading external config..."
    wget -q ${MANGOS_OVERRIDE_CONF_URL} -O /opt/mangos/etc/mangosd.conf
    setup_init
else
    setup_init
fi

# debug: exec "bin/mangosd" -c conf/mangosd.conf
# debug: exec "bin/realmd" -c conf/realmd.conf
exec "$@"
