FROM debian:10.3-slim

LABEL maintainer="meteorIT GbR Marcus Kastner"

EXPOSE 143 80 2003

#has to be specified at build time
ARG	KOPANO_SERIAL=""

ENV	DB_HOST="" \
	DB_NAME=kopano \
	DB_USER=kopano \
	DB_PASS=kopano \
	DB_PORT=3306 \
	DB_NAME_ZPUSH=zpush \
	ATTACHMENT_STORAGE=database \
	ATTACHMENT_PATH="attachments" \
	ATTACHMENT_S3_HOSTNAME="" \
	ATTACHMENT_S3_PROTOCOL="http" \
	ATTACHMENT_S3_ACCESS_KEY="" \
	ATTACHMENT_S3_SECRET_ACCESS_KEY="" \
	ATTACHMENT_S3_BUCKET_NAME="kopano-attachments" \
	LOG_LEVEL=3 \
	SMTP_SERVER=""\
	MESSAGE_TO_ME=True \
	DEBIAN_FRONTEND=noninteractive \
	TIMEZONE="Europe/Berlin" \
	DOCKERIZE_VERSION=v0.6.1 \
	LANG=de_DE.UTF-8

# gerneral packages
RUN apt update \
	&& apt -y dist-upgrade \
	&& apt install -y --no-install-recommends \
	apt-transport-https \
	ca-certificates \
	cron \
	curl \
	gnupg2 \
	vim \
	tar \
	locales \
	apache2 \
	libapache2-mod-php \
	net-tools \
	&& rm -rf  /var/cache/apt  /var/lib/apt/lists/*

# set locale
RUN sed -i -e "s/# $LANG UTF-8/$LANG UTF-8/" /etc/locale.gen \
	&& locale-gen

# kopano installation
RUN echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/Debian_10/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/webapp:/final/Debian_10/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/files:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/mdm:/final/Debian_9.0/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb http://repo.z-hub.io/z-push:/final/Debian_10/ /" >>  /etc/apt/sources.list.d/z-push.list \
	&& curl https://repo.z-hub.io/z-push:/final/Debian_10/Release.key | apt-key add - \
	&& apt update \
	&& apt install -y  --no-install-recommends \
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
	z-push-config-apache \
	z-push-state-sql \
	z-push-kopano-gabsync \
	python-kopano \
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
ADD scripts /srv/scripts

#edit Config Files
RUN sed -i "s|LANG.*|LANG=$LANG|g" /etc/apache2/envvars \
	&& phpenmod kopano \
	&& cp /srv/templates/cron/crontab /etc/crontab \
	&& chown -R www-data:www-data /var/lib/z-push \
	&& chown -R www-data:www-data /var/log/z-push \
	&& chown -R www-data:www-data /etc/z-push


# create log-files
RUN mkdir -p /var/log/kopano/ \
	&& chown kopano /var/log/kopano/ \
	&& touch /var/log/kopano/autorespond.log \
	&& touch /var/log/z-push/z-push-error.log \
	&& touch /var/log/z-push/z-push.log

# set timezone
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone \
	&& chmod 777 /srv/scripts/*

HEALTHCHECK CMD bash /srv/scripts/healthcheck.sh
ENTRYPOINT ["/srv/scripts/entrypoint.sh"]
