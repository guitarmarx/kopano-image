FROM debian:9.4-slim

LABEL maintainer="meteorIT GbR Marcus Kastner"

EXPOSE 993 80 2003

#has to be specified at build time
ARG	KOPANO_SERIAL=""

ENV	DOMAIN="" \
	DB_HOST="" \
	DB_NAME=kopano \
	DB_USER=kopano \
	DB_PASS=kopano \
	DB_NAME_ZPUSH=zpush \
	SMTP_SERVER=""\
	DEBIAN_FRONTEND=noninteractive \
	NGINX_API_KEY="" \
	TIMEZONE="Europe/Berlin" \
	PHP_UPLOAD_MAX_FILESIZE="2030M" \
	PHP_POST_MAX_SIZE="2040M" \
	PHP_MEMORY_LIMIT="2048M" \
	FPM_MAX_CHILDREN=40

# gerneral packages
RUN apt update \
	&& apt -y dist-upgrade \
	&& apt install -y curl gnupg2 apt-transport-https vim ssmtp python2.7 cron \
	&& apt install -y nginx php7.0-fpm php7.0-mysql  \
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
	&& curl https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/Debian_9.0/Release.key | apt-key add - \
	&& curl https://serial:$KOPANO_SERIAL@download.kopano.io/supported/webapp:/final/Debian_9.0/Release.key | apt-key add - \
	&& curl https://serial:$KOPANO_SERIAL@download.kopano.io/supported/files:/final/Debian_9.0/Release.key | apt-key add - \
	&& curl https://serial:$KOPANO_SERIAL@download.kopano.io/supported/mdm:/final/Debian_9.0/Release.key | apt-key add - \
	&& curl http://repo.z-hub.io/z-push:/final/Debian_9.0/Release.key | apt-key add - \
	&& apt update \
	&& apt install -y z-push-kopano  z-push-state-sql \
	&& apt install -y kopano-server-packages kopano-webapp \
	&& apt install -y kopano-webapp-plugin-filepreviewer kopano-webapp-plugin-files kopano-webapp-plugin-filesbackend-owncloud  \
	&& apt install -y kopano-webapp-plugin-titlecounter kopano-webapp-plugin-quickitems kopano-webapp-plugin-folderwidgets kopano-webapp-plugin-mdm \
	&& apt install -y kopano-webapp-plugin-spell-de-de kopano-webapp-plugin-spell-en kopano-webapp-plugin-webappmanual \
	&& rm -rf  /var/cache/apt  /var/lib/apt/lists/*

# save config files
RUN mkdir -p /tmp/kopano_default/config/ \
	&& mkdir -p /tmp/kopano_default/plugins/ \
	&& cp -r /etc/kopano/* /tmp/kopano_default/config/ \
	&& cp -r /usr/share/kopano-webapp/plugins/* /tmp/kopano_default/plugins/


ADD templates /tmp/templates
ADD entrypoint.sh /tmp

# set time
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone \
	&& chmod 777 /tmp/entrypoint.sh

ENTRYPOINT ["/tmp/entrypoint.sh"]



