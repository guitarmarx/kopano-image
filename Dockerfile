FROM debian:9.6-slim

LABEL maintainer="meteorIT GbR Marcus Kastner"

EXPOSE 993 80 2003

#has to be specified at build time
ARG	KOPANO_SERIAL=""

ENV	DOMAIN="" \
	DB_HOST="" \
	DB_NAME=kopano \
	DB_USER=kopano \
	DB_PASS=kopano \
	DB_PORT=3306 \
	DB_NAME_ZPUSH=zpush \
	SMTP_SERVER=""\
	DEBIAN_FRONTEND=noninteractive \
	NGINX_API_KEY="" \
	TIMEZONE="Europe/Berlin" \
	DOCKERIZE_VERSION=v0.6.1


# gerneral packages
RUN apt update \
	&& apt -y dist-upgrade \
	&& apt install -y \
	apt-transport-https \
	cron \
	curl \
	gnupg2 \
	nginx-light \
	php7.0-fpm \
	php7.0-mysql  \
	python2.7 \
	ssmtp \
	vim \
	tar \
	&& rm -rf  /var/cache/apt  /var/lib/apt/lists/*

#nginx-aplify installation
RUN curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh \
	&& sed -i "s/apt-get/apt-get -y/g" install.sh \
	&& sed -i "s/service amplify-agent start/service amplify-agent stop/g" install.sh \
	&& API_KEY=0000 sh ./install.sh \
	&& rm -rf  /var/cache/apt  /var/lib/apt/lists/*

# kopano installation
RUN echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano-core.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/webapp:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano-core.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/files:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano-core.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/mdm:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano-core.list \
	&& echo "deb http://repo.z-hub.io/z-push:/final/Debian_9.0/ /" >>  /etc/apt/sources.list.d/z-push.list \
	&& curl http://repo.z-hub.io/z-push:/final/Debian_9.0/Release.key | apt-key add - \
	&& apt update \
	&& apt install -y \
	kopano-server-packages \
	kopano-webapp \
	kopano-webapp-plugin-filepreviewer \
	kopano-webapp-plugin-files \
	kopano-webapp-plugin-filesbackend-owncloud \
	kopano-webapp-plugin-folderwidgets \
	kopano-webapp-plugin-mdm \
	kopano-webapp-plugin-quickitems \
	kopano-webapp-plugin-spell-de-de \
	kopano-webapp-plugin-spell-en \
	kopano-webapp-plugin-titlecounter \
	z-push-kopano \
	z-push-state-sql \
	z-push-kopano-gabsync \
	&& rm -rf  /var/cache/apt  /var/lib/apt/lists/*


# download dockerize
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz --output /tmp/dockerize.tar.gz  \
	&& tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
	&& rm /tmp/dockerize.tar.gz

# save config files for later usage
RUN mkdir -p /srv/kopano_default/config/ \
	&& mkdir -p /srv/kopano_default/plugins/ \
	&& cp -r /etc/kopano/* /srv/kopano_default/config/ \
	&& cp -r /usr/share/kopano-webapp/plugins/* /srv/kopano_default/plugins/

ADD templates /srv/templates
ADD entrypoint.sh /srv

#edit Config Files
RUN cp /srv/templates/php/20-kopano.ini /etc/php/7.0/fpm/conf.d/ \
	&& /srv/templates/php/webapp.conf /etc/php/7.0/fpm/conf.d/ \
	&& rm /etc/nginx/sites-enabled/* \
	&& cp /srv/templates/nginx/webapp.conf /etc/nginx/sites-enabled \
	&& cp /srv/templates/cron/crontab /etc/crontab

# create log-files
RUN mkdir -p /var/log/kopano/ \
	&& chown kopano /var/log/kopano/ \
	&& touch /var/log/kopano/autorespond.log \
	&& touch /var/log/z-push/z-push-error.log \
	&& touch /var/log/z-push/z-push.log


# set timezone
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone \
	&& chmod 777 /srv/entrypoint.sh

ENTRYPOINT ["/srv/entrypoint.sh"]
