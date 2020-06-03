#!/bin/bash

##########   Configuration   ############
dockerize -template /srv/templates/core/:/etc/kopano/
dockerize -template /srv/templates/webapp/:/etc/kopano/webapp
dockerize -template /srv/templates/zpush/:/etc/z-push/

#copy additional pluggins
cp -r /srv/plugins/* /usr/share/kopano-webapp/plugins/

# edit z-push.conf.php
TIMEZONE=${TIMEZONE//\//\\/}
sed -i "s/('TIMEZONE', '')/('TIMEZONE', '$TIMEZONE');/g" /etc/z-push/*
sed -i "s/('STATE_MACHINE'.*/('STATE_MACHINE', 'SQL');/g" /etc/z-push/z-push.conf.php
sed -i "s/('USE_FULLEMAIL_FOR_LOGIN'.*/('USE_FULLEMAIL_FOR_LOGIN', 'true');/g" /etc/z-push/autodiscover.conf.php


# edit Apache Alias
sed -i "s|Alias.*|Alias / /usr/share/kopano-webapp/|g" /etc/apache2/sites-available/kopano-webapp.conf

#edit gabsync.conf.php
sed -i "s/define('USERNAME', '');/define('USERNAME', 'SYSTEM');/g" /etc/z-push/gabsync.conf.php

# edit kopano-autorepond
cat /srv/templates/kopano-autorespond.py > /usr/sbin/kopano-autorespond


##########   Start Services   ############
echo "waiting for connection to database ...  "
dockerize -wait tcp://$MYSQL_HOST:$MYSQL_PORT

kopano-server

kopano-dagent -d
kopano-spooler
kopano-gateway
kopano-ical
kopano-search

php-fpm7.0
service apache2 start

# wait for log creation
sleep 10 

tail -f  /var/log/kopano/*  /var/log/z-push/*