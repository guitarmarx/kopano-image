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

#copy templates to kopnao config folder
dockerize -template /srv/kopano/config-templates:/etc/kopano


#create default kopano config
cp -n /srv/templates/kopano/kopano /etc/default/


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
####################   START  ###############################
#############################################################

# start services
echo "waiting for connection to database ...  "
dockerize -wait tcp://$DB_HOST:$DB_PORT

service php7.0-fpm start
kopano-server
kopano-dagent -l
kopano-spooler
kopano-gateway
kopano-ical
kopano-search

service nginx start
service cron start

# send log output to docker sstout
tail -f  /var/log/kopano/* /var/log/nginx/* /var/log/z-push/*
