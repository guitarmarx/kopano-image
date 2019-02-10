#!/bin/bash

###################################################
#################   KOPANO Config ###########################
#############################################################

# copy default config files (necessary to recreate config folder when bind as docker volume)
cp -r -n /srv/kopano_default/config/* /etc/kopano/
cp -r -n /srv/kopano_default/plugins/* /usr/share/kopano-webapp/plugins/

#copy templates to kopnao config folder
dockerize -template /srv/templates/kopano/config-templates:/etc/kopano

# edit kopano-autorepond
cat /srv/templates/kopano/kopano-autorespond.sh > /usr/sbin/kopano-autorespond
cp /srv/templates/kopano/kopano-autorespond.py > /usr/sbin/kopano-autorespond.py

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
dockerize -template /srv/templates/z-push/state-sql.conf.php:/etc/z-push/state-sql.conf.php

#edit gabsync.conf.php
sed -i "s/define('USERNAME', '');/define('USERNAME', 'SYSTEM');/g" /etc/z-push/gabsync.conf.php
chmod -R 777 /var/log/z-push

#############################################################
####################   START  ###############################
#############################################################

# start services
echo "waiting for connection to database ...  "
dockerize -wait tcp://$DB_HOST:$DB_PORT

export LC_ALL=$LANG
export KOPANO_LOCALE=$LANG
export KOPANO_USERSCRIPT_LOCALE=$LANG

service php7.0-fpm start
kopano-server
kopano-dagent -d
kopano-spooler
kopano-gateway
kopano-ical
kopano-search

service nginx start
service cron start

# send log output to docker sstout
tail -f  /var/log/kopano/* /var/log/nginx/* /var/log/z-push/*