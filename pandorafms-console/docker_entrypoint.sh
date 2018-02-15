#!/bin/bash
set -e
if [ -n "$MYSQL_PORT_3306_TCP" ]; then
		if [ -z "$PANDORA_DB_HOST" ]; then
			PANDORA_DB_HOST='mysql'
		else
			echo >&2 'warning: both PANDORA_DB_HOST and MYSQL_PORT_3306_TCP found'
			echo >&2 "  Connecting to PANDORA_DB_HOST ($PANDORA_DB_HOST)"
			echo >&2 '  instead of the linked mysql container'
		fi
fi

if [ -z "$PANDORA_DB_HOST" ]; then
	echo >&2 'error: missing PANDORA_DB_HOST and MYSQL_PORT_3306_TCP environment variables'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql or set an external db'
	echo >&2 '  with -e PANDORA_DB_HOST=hostname:port?'
	exit 1
fi

# if we're linked to MySQL and thus have credentials already, let's use them
: ${PANDORA_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}
if [ "$PANDORA_DB_USER" = 'root' ]; then
	: ${PANDORA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${PANDORA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
if [ -z "$PANDORA_DB_NAME" ]; then
	: ${PANDORA_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-pandora}}
fi

if [ -z "$PANDORA_DB_PASSWORD" ]; then
	echo >&2 'error: missing required PANDORA_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e PANDORA_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be PANDORA_DB_USER and PANDORA_DB_NAME.)'
	exit 1
fi

mv -f /tmp/pandorafms/pandora_console /var/www/html
cd /var/www/html/pandora_console/include

HOMEURL="${HOMEURL:-/pandora_console}"
HOMEURL_STATIC="${HOMEURL_STATIC:-${HOMEURL}}"

cat > config.php <<- EOF
<?php
\$config["dbtype"] = "mysql";
\$config["homedir"]="/var/www/html/pandora_console";             // Config homedir
\$config["homeurl"]="${HOMEURL}";                  // Base URL
\$config["homeurl_static"]="${HOMEURL_STATIC}";                   // Don't  delete
error_reporting(E_ALL);
\$ownDir = dirname(__FILE__) . DIRECTORY_SEPARATOR;
\$config["dbname"]="${PANDORA_DB_NAME}";
\$config["dbuser"]="${PANDORA_DB_USER}";
\$config["dbpass"]="${PANDORA_DB_PASSWORD}";
\$config["dbhost"]="${PANDORA_DB_HOST}";
\$config["public_url"]="${PUBLIC_URL}";
\$config["https"]=${HTTPS:-false};
include (\$ownDir . "config_process.php");
?>
EOF

echo "Granting apache permissions to the console directory"
chown -R apache:apache /var/www/html/pandora_console
chmod 600 /var/www/html/pandora_console/include/config.php

# Customize php.iniA
echo "Configuring Pandora FMS elements and depending services"
sed "s/.*error_reporting =.*/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_NOTICE \& \~E_USER_WARNING/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini
sed "s/.*max_execution_time =.*/max_execution_time = 0/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini
sed "s/.*max_input_time =.*/max_input_time = -1/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini
sed "s/.*upload_max_filesize =.*/upload_max_filesize = 800M/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini
sed "s/.*memory_limit =.*/memory_limit = 500M/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini
sed "s/.*post_max_size =.*/post_max_size = 100M/" /etc/php.ini > /tmp/php.ini && mv /tmp/php.ini /etc/php.ini

cd /var/www/html/pandora_console && mv -f install.php install.php.done

cat <<EOF > /var/www/html/index.html
<html>
<head>
<meta HTTP-EQUIV="REFRESH" content="0; url=pandora_console/index.php">
</head>
</html>
EOF

#Create the pandora user
/usr/sbin/useradd -d /home/pandora -s /bin/false -M -g 0 pandora

#Import the ACME ssl cert
if [ -f /ssl/acme.json ]; then
  jq -r .DomainsCertificate.Certs[0].Certificate.PrivateKey /ssl/acme.json   | base64 -d  > /etc/ssl/certs/pandorafms.pem
  echo "" >> /etc/ssl/certs/pandorafms.pem
  jq -r .DomainsCertificate.Certs[0].Certificate.Certificate /ssl/acme.json   | base64 -d >> /etc/ssl/certs/pandorafms.pem
fi

#Rock n' roll!
/etc/init.d/crond start &
/etc/init.d/ntpd start &

rm -rf /run/httpd/*
exec /usr/sbin/apachectl -D FOREGROUND
