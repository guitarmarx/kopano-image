#!/bin/bash

#############################################################
#####################   GENERAL #############################
#############################################################

### set german locale ###
sed -i "s/# set convert-meta off/set convert-meta off/g" /etc/inputrc
echo -e 'LANG="de_DE.UTF-8"\nLANGUAGE="de_DE:de"\n' > /etc/default/locale

# permit root login if sshd is installed --> necessary to add user with umlaut ###
# sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# edit ssmtp for autorespond
sed -i "s/mailhub=.*/mailhub=$SMTP_SERVER/" /etc/ssmtp/ssmtp.conf
sed -i "s/#FromLineOverride=.*/FromLineOverride=YES/" /etc/ssmtp/ssmtp.conf

# edit nginx config
cp /tmp/templates/nginx/nginx.conf /etc/nginx/nginx.conf

# edit crontab
cp /tmp/templates/cron/crontab /etc/crontab


#############################################################
#################   KOPANO Config ###########################
#############################################################

# copy default config files (necessary to recreate config folder when bind as docker volume)
cp -r -n /tmp/kopano_default/config/* /etc/kopano/
cp -r -n /tmp/kopano_default/plugins/* /usr/share/kopano-webapp/plugins/

#create default kopano config
cp -n /tmp/templates/kopano/kopano /etc/default/

# edit gateway.cfg
sed -i "s/#server_hostname =.*/server_hostname = $DOMAIN/g" /etc/kopano/gateway.cfg

# edit server.cfg
sed -i "s/^mysql_host.*/mysql_host = $DB_HOST/g" /etc/kopano/server.cfg
sed -i "s/^mysql_user.*/mysql_user = $DB_USER/g" /etc/kopano/server.cfg
sed -i "s/^mysql_password.*/mysql_password = $DB_PASS/g" /etc/kopano/server.cfg
sed -i "s/^mysql_database.*/mysql_database = $DB_NAME/g" /etc/kopano/server.cfg

# edit spooler.cfg
sed -i "s/^smtp_server.*/smtp_server = $SMTP_SERVER/g" /etc/kopano/spooler.cfg

# edit kopano-autorepond
cat /tmp/templates/kopano/kopano-autorespond.sh > /usr/sbin/kopano-autorespond

# create empty log files
mkdir -p /var/log/kopano/
touch /var/log/kopano/autorespond.log
touch /var/log/z-push/z-push-error.log
touch /var/log/z-push/z-push.log

#############################################################
######################   PHP Config #########################
#############################################################

# copy kopano php config
cp /tmp/templates/php/20-kopano.ini /etc/php/7.0/fpm/conf.d/20-kopano.ini

# edit php.ini for z-push
echo "php_flag magic_quotes_gpc = off" >> /etc/php/7.0/fpm/php.ini
echo "php_flag register_globals = off" >> /etc/php/7.0/fpm/php.ini
echo "php_flag magic_quotes_runtime = off" >> /etc/php/7.0/fpm/php.ini
echo "php_flag short_open_tag = on" >> /etc/php/7.0/fpm/php.ini

# edit PHP-FPM config or kopano performance
sed -i  "s/post_max_size =.*/post_max_size = $PHP_POST_MAX_SIZE/g"  /etc/php/7.0/fpm/php.ini
sed -i  "s/upload_max_filesize =.*/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/g"  /etc/php/7.0/fpm/php.ini
sed -i  "s/memory_limit = .*/memory_limit = $PHP_MEMORY_LIMIT/g"  /etc/php/7.0/fpm/php.ini

sed -i "s/;pm.status_path = \/status/pm.status_path = \/status/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/pm.max_children.*/pm.max_children = $FPM_MAX_CHILDREN/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/pm.start_servers.*/pm.start_servers = 5/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/pm.min_spare_servers.*/pm.min_spare_servers = 5/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/pm.max_spare_servers.*/pm.max_spare_servers = 10/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;pm.max_requests.*/pm.max_requests = 500/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;request_slowlog_timeout.*/request_slowlog_timeout = 5s/g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;slowlog.*/slowlog = \/var\/log\/slowlog.log.slow/g" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/;emergency_restart_threshold.*/emergency_restart_threshold = 10/g" /etc/php/7.0/fpm/php-fpm.conf
sed -i "s/;emergency_restart_interval.*/emergency_restart_interval = 1m/g" /etc/php/7.0/fpm/php-fpm.conf
sed -i "s/;process_control_timeout.*/process_control_timeout = 10/g" /etc/php/7.0/fpm/php-fpm.conf


#############################################################
####################   ZPUSH Config #########################
#############################################################

# change right to z-push folders
chown -R www-data:www-data /var/lib/z-push
chown -R www-data:www-data /var/log/z-push

# edit z-push.conf.php

="Europe\/Berlin"
TIMEZONE=${TIMEZONE//\//\\/}
sed -i "s/('TIMEZONE', '')/('TIMEZONE', '$TIMEZONE');/g" /etc/z-push/z-push.conf.php
sed -i "s/('STATE_MACHINE'.*/('STATE_MACHINE', 'SQL');/g" /etc/z-push/z-push.conf.php
# edit state-sql.conf.php
sed -i "s/('STATE_SQL_SERVER'.*/('STATE_SQL_SERVER', '$DB_HOST');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_DATABASE'.*/('STATE_SQL_DATABASE', '$DB_NAME_ZPUSH');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_USER'.*/('STATE_SQL_USER', '$DB_USER');/g" /etc/z-push/state-sql.conf.php
sed -i "s/('STATE_SQL_PASSWORD'.*/('STATE_SQL_PASSWORD', '$DB_PASS');/g" /etc/z-push/state-sql.conf.php



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
service php7.0-fpm start
service kopano-dagent start
service kopano-spooler start
service kopano-gateway start
service kopano-ical start
service kopano-search start
service nginx start
service cron start

# start kopano-server (restart till database is available)
statuscode=3
while [  $statuscode -ne 0 ]
do
	service kopano-server start
	service kopano-server status
	statuscode=$?

	echo "Returncode: " $statuscode

	if [ $statuscode -ne 0 ];then
		tail -n 4 /var/log/kopano/server.log
	fi
done

# send log output to docker sstout
tail -f  /var/log/kopano/* /var/log/nginx/* /var/log/z-push/*
