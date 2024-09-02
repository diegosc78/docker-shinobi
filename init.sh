#!/bin/sh
set -e

OLD_SQL_USER_TAG="ccio"
NEW_SQL_USER_TAG="$DB_DATABASE"
if [ "$SSL_ENABLED" = "true" ]; then
    if [ -d /config/ssl ]; then
        echo "Using provided SSL Key"
        cp -R /config/ssl ./
        SSL_CONFIG='{"key":"./ssl/server.key","cert":"./ssl/server.cert"}'
    else
        echo "Making new SSL Key"
        mkdir -p ssl
        openssl req -nodes -new -x509 -keyout ssl/server.key -out ssl/server.cert -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_LOCATION/O=$SSL_ORGANIZATION/OU=$SSL_ORGANIZATION_UNIT/CN=$SSL_COMMON_NAME"
        cp -R ssl /config/ssl
        SSL_CONFIG='{"key":"./ssl/server.key","cert":"./ssl/server.cert"}'
    fi
else
    SSL_CONFIG='{}'
fi
if [ "$DB_DISABLE_INCLUDED" = "false" ]; then
    echo "MariaDB Directory ..."
    ls /var/lib/mysql

    if [ ! -f /var/lib/mysql/ibdata1 ]; then
        echo "Installing MariaDB ..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql --silent
    fi
    echo "Starting MariaDB ..."
    /usr/bin/mysqld_safe --user=mysql &
    sleep 5s

    chown -R mysql /var/lib/mysql

    if [ ! -f /var/lib/mysql/ibdata1 ]; then
        mysql -u root --password="" -e "SET @@SESSION.SQL_LOG_BIN=0;
        USE mysql;
        DELETE FROM mysql.user ;
        DROP USER IF EXISTS 'root'@'%','root'@'localhost','${DB_USER}'@'localhost','${DB_USER}'@'%';
        CREATE USER 'root'@'%' IDENTIFIED BY '${DB_PASS}' ;
        CREATE USER 'root'@'localhost' IDENTIFIED BY '${DB_PASS}' ;
        CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}' ;
        CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}' ;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION ;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
        GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION ;
        GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION ;
        DROP DATABASE IF EXISTS test ;
        FLUSH PRIVILEGES ;"
    fi

    # Create MySQL database if it does not exists
    if [ -n "${DB_HOST}" ]; then
        echo "Wait for MySQL server" ...
        while ! mysqladmin ping -h"$DB_HOST"; do
            sleep 1
        done
    fi

    echo "Create database user if it does not exists ..."
    mysql -e "source /home/Shinobi/sql/user.sql" || true

else
    echo "Create database schema if it does not exists ..."
fi

DATABASE_CONFIG='{"host": "'$DB_HOST'","user": "'$DB_USER'","password": "'$DB_PASSWORD'","database": "'$DB_DATABASE'","port":'$DB_PORT'}'

cronKey="$(head -c 1024 < /dev/urandom | sha256sum | awk '{print substr($1,1,29)}')"

cd /home/Shinobi
mkdir -p libs/customAutoLoad

if [ -e "/config/conf.json" ]; then
    cp /config/conf.json conf.json
elif [ ! -e "./conf.json" ]; then
    cp conf.sample.json conf.json
fi
# Create /config/conf.json if it doesn't exist
if [ ! -e "/config/conf.json" ]; then
  node tools/modifyConfiguration.js cpuUsageMarker=CPU subscriptionId=$SUBSCRIPTION_ID thisIsDocker=true pluginKeys="$PLUGIN_KEYS" databaseType="$DB_TYPE" db="$DATABASE_CONFIG" ssl="$SSL_CONFIG"
  cp /config/conf.json conf.json
fi
sed -i -e 's/change_this_to_something_very_random__just_anything_other_than_this/'"$cronKey"'/g' conf.json
# (DSC) Activate mqtt!
node tools/modifyConfiguration.js addToConfig='{"mqttClient":true}'

echo "============="
echo "Default Superuser : admin@shinobi.video"
echo "Default Password : admin"
echo "Log in at http://HOST_IP:SHINOBI_PORT/super"
if [ -e "/config/super.json" ]; then
    cp /config/super.json super.json
elif [ ! -e "./super.json" ]; then
    cp super.sample.json super.json
fi

if [ -e "/config/init.extension.sh" ]; then
    echo "Running extension init file ..."
    ( sh /config/init.extension.sh )
fi

# Execute Command
echo "Starting Shinobi ..."
exec "$@"
