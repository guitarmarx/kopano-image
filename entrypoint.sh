#!/bin/bash

#############################################################
#####################   GENERAL #############################
#############################################################

### set german locale ###
sed -i "s/# set convert-meta off/set convert-meta off/g" /etc/inputrc
echo -e 'LANG="de_DE.UTF-8"\nLANGUAGE="de_DE:de"\n' > /etc/default/locale

# permit root login if sshd is installed --> necessary to add user with umlaut ###
# sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config


#############################################################
#################   KOPANO Config ###########################
#############################################################

# copy default config files (necessary to recreate config folder when bind as docker volume)
cp -r -n /srv/kopano_default/config/* /etc/kopano/
cp -r -n /srv/kopano_default/plugins/* /usr/share/kopano-webapp/plugins/

#create default kopano config
cp -n /srv/templates/kopano/kopano /etc/default/

# edit gateway.cfg
sed -i "s/#server_hostname =.*/server_hostname = $DOMAIN/g" /etc/kopano/gateway.cfg

# edit server.cfg
sed -i "s/.*mysql_host.*=.*/mysql_host = $DB_HOST/g" /etc/kopano/server.cfg
sed -i "s/.*mysql_user.*=.*/mysql_user = $DB_USER/g" /etc/kopano/server.cfg
sed -i "s/.*mysql_password.*=.*/mysql_password = $DB_PASS/g" /etc/kopano/server.cfg
sed -i "s/.*mysql_database.*=.*/mysql_database = $DB_NAME/g" /etc/kopano/server.cfg

# edit spooler.cfg
sed -i "s/.*smtp_server.*=.*/smtp_server = $SMTP_SERVER/g" /etc/kopano/spooler.cfg

# edit kopano-autorepond
cat /srv/templates/kopano/kopano-autorespond.sh > /usr/sbin/kopano-autorespond

# edit ssmtp for autorespond
sed -i "s/mailhub=.*/mailhub=$SMTP_SERVER/" /etc/ssmtp/ssmtp.conf
sed -i "s/#FromLineOverride=.*/FromLineOverride=YES/" /etc/ssmtp/ssmtp.conf

#############################################################
####################   ZPUSH Config #########################
#############################################################

# edit z-push.conf.php
TIMEZONE=${TIMEZONE//\//\\/}
sed -i "s/('TIMEZONE', '')/('TIMEZONE', '$TIMEZONE');/g" /etc/z-push/z-push.conf.php
sed -i "s/('STATE_MACHINE'.*/('STATE_MACHINE', 'SQL');/g" /etc/z-push/z-push.conf.php
# edit state-sql.conf.php
sed -i "s/('STATE_SQL_SERVER'.*/('STATE_SQL_SERVER', '$DB_HOST');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_DATABASE'.*/('STATE_SQL_DATABASE', '$DB_NAME_ZPUSH');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_USER'.*/('STATE_SQL_USER', '$DB_USER');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_PASSWORD'.*/('STATE_SQL_PASSWORD', '$DB_PASS');/g" /etc/z-push/state-sql.conf.php

#edit gabsync.conf.php
sed -i "s/define('USERNAME', '');/define('USERNAME', 'SYSTEM');/g" /etc/z-push/gabsync.conf.php

chmod -R 777 /var/log/z-push


#############################################################
####################   NGINX Amplify  #######################
#############################################################

# start if nginx_amplify_api_key is set
if [ ! -z "$NGINX_API_KEY" ]; then
	# edit amplify config
	sed -i "s/api_key .*/api_key = $NGINX_API_KEY/g" /etc/amplify-agent/agent.conf
	sed -i "s/hostname .*/hostname = kopano\.$DOMAIN/g" /etc/amplify-agent/agent.conf
	sed -i "s/uuid =.*/uuid = 0f2c2dcf00205d45a6eba415b862bba1/g" /etc/amplify-agent/agent.conf

	#start nginx amplify
	echo "Start nginx amplify"
	service amplify-agent start
else
	echo "Nginx Amplify not started, NGINX_API_KEY not set"
fi

#############################################################
####################   START  ###############################
#############################################################

# start services
echo "waiting for connection to database ...  "
dockerize -wait tcp://$DB_HOST:$DB_PORT

service php7.0-fpm start
service kopano-server start
service kopano-dagent start
service kopano-spooler start
service kopano-gateway start
service kopano-ical start
service kopano-search start
service nginx start
service cron start

# send log output to docker sstout
tail -f  /var/log/kopano/* /var/log/nginx/* /var/log/z-push/*
