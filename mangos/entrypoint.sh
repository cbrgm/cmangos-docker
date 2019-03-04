#!/bin/bash
echo "cbrgm/mangos written by Christian Bargmann (c) 2019"
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
    if [ -z "${MYSQL_DATABASE_CHARACTER}" ]; then echo "Missing MYSQL_DATABASE_CHARACTER environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_REALM}" ]; then echo "Missing MYSQL_DATABASE_REALM environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MYSQL_DATABASE_WORLD}" ]; then echo "Missing MYSQL_DATABASE_WORLD environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MANGOS_DATABASE_RELEASE}" ]; then echo "Missing MANGOS_DATABASE_RELEASE environment variable. Unable to continue."; exit 1; fi
    if [ -z "${MANGOS_DATABASE_REALM_NAME}" ]; then echo "Missing MANGOS_DATABASE_REALM_NAME environment variable. Unable to continue."; exit 1; fi

    echo "Checking if databases already exists..."
    if  ! check_database_exists; then
        echo "Setting up MySQL config..."
        echo "Cloning latest database files..."
        git clone https://github.com/${MANGOS_BUILDIN_VERSION}/database.git -b master --recursive

        echo "###### General database setup ######"
        echo "Creating databases..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} < database/World/Setup/mangosdCreateDB.sql

        echo "###### World database setup ######"
        echo "Loading world database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < database/World/Setup/mangosdLoadDB.sql
        echo "Migrating world database..."
        cat database/World/Setup/FullDB/*.sql > database/World/Setup/FullDB/migrate.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < database/World/Setup/FullDB/migrate.sql
        echo "Patching world database..."
        cat database/World/Updates/${MANGOS_DATABASE_RELEASE}/*.sql  > database/World/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_WORLD} < database/World/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql

        echo "###### Character database setup ######"
        echo "Loading character database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_CHARACTER} < database/Character/Setup/characterLoadDB.sql
        echo "Patching character database..."
        cat database/Character/Updates/${MANGOS_DATABASE_RELEASE}/*.sql  > database/Character/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_CHARACTER} < database/Character/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql

        echo "###### Realm database setup ######"
        echo "Loading realm database..."
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} < database/Realm/Setup/realmdLoadDB.sql
        echo "Patching realm database..."
        cat database/Realm/Updates/${MANGOS_DATABASE_RELEASE}/*.sql  > database/Realm/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} < database/Realm/Updates/${MANGOS_DATABASE_RELEASE}/patch.sql

        # Adding entry to realmlist
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "INSERT INTO realmlist (name,address,realmbuilds) VALUES ('${MANGOS_DATABASE_REALM_NAME}','${MANGOS_SERVER_PUBLIC_IP}','12340');"

        # Deleting all example entries from accounts db
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "TRUNCATE account;"

        # Add gamemaster account
        if ! [ -z "${MANGOS_GM_ACCOUNT}" ] && ! [ -z "${MANGOS_GM_PWD}" ]; then
            mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DATABASE_REALM} -e "INSERT INTO account (username,sha_pass_hash,gmlevel,expansion) VALUES ('${MANGOS_GM_ACCOUNT}', SHA1(CONCAT(UPPER('${MANGOS_GM_ACCOUNT}'),':',UPPER('${MANGOS_GM_PWD}'))),'4','2');"
        fi

        # Cleanup
        rm -rf /opt/mangos/database
    fi
}

setup_config() {
  echo "###### Mangos config setup ######"
  echo "Configuring /opt/mangos/conf/mangosd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_USER};${MYSQL_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/conf/mangosd.conf
  sed -i "s/^WorldDatabaseInfo.*/WorldDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_USER};${MYSQL_PWD};${MYSQL_DATABASE_WORLD}/" /opt/mangos/conf/mangosd.conf
  sed -i "s/^CharacterDatabaseInfo.*/CharacterDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_USER};${MYSQL_PWD};${MYSQL_DATABASE_CHARACTER}/" /opt/mangos/conf/mangosd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/conf/mangosd.conf

  # Gameplay specific options...
  if ! [ -z "${MANGOS_GAMETYPE}" ]; then sed -i "s/^GameType.*/GameType = ${MANGOS_GAMETYPE}/" /opt/mangos/conf/mangosd.conf; fi
  if ! [ -z "${MANGOS_MOTD}" ]; then sed -i "s/^Motd.*/Motd = ${MANGOS_MOTD}"/ /opt/mangos/conf/mangosd.conf; fi

  echo "Configuring /opt/mangos/conf/realmd.conf..."
  sed -i "s/^LoginDatabaseInfo.*/LoginDatabaseInfo = ${MYSQL_HOST};${MYSQL_PORT};${MYSQL_USER};${MYSQL_PWD};${MYSQL_DATABASE_REALM}/" /opt/mangos/conf/realmd.conf
  sed -i "s/^BindIP.*/BindIP = ${MANGOS_SERVER_IP}/" /opt/mangos/conf/realmd.conf
}

sleep 10
setup_init
# debug: exec "bin/mangosd" -c conf/mangosd.conf
# debug: exec "bin/realmd" -c conf/realmd.conf
exec "$@"
