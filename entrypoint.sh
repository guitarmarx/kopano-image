#!/bin/bash


#############################################################
#################   KOPANO Config ###########################
#############################################################

# copy default config files (necessary to recreate config folder when bind as docker volume)
cp -r -n /srv/kopano_default/config/* /etc/kopano/
cp -r -n /srv/kopano_default/plugins/* /usr/share/kopano-webapp/plugins/

#copy templates to kopnao config folder
dockerize -template /srv/templates/kopano/config-templates:/etc/kopano

# edit kopano-autorepond
cat /srv/templates/kopano/kopano-autorespond.py > /usr/sbin/kopano-autorespond

# edit kopano-localize-folders
sed -i "s|import sys|import sys\nreload(sys)\nsys.setdefaultencoding('UTF8')|g" /usr/sbin/kopano-localize-folders

# edit Apache Alias
sed -i "s|Alias.*|Alias / /usr/share/kopano-webapp/|g" /etc/apache2/sites-available/kopano-webapp.conf


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

service apache2 start
service cron start

# send log output to docker sstout
tail -f  /var/log/kopano/* /var/log/nginx/* /var/log/z-push/*