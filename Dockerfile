FROM debian:9.12

LABEL maintainer="meteorIT GbR Marcus Kastner"

EXPOSE  2003 143 80

ARG KOPANO_UID=999
ARG KOPANO_GID=999
ARG KOPANO_SERIAL=""
ARG OS_VERSION=Debian_9.0
ARG	DOCKERIZE_VERSION=v0.6.1

ENV DEBIAN_FRONTEND=noninteractive \
    SYSTEM_EMAIL=postmaster@localhost \
    LANG=de_DE.UTF-8 \
    LOG_LEVEL=3 \
    MYSQL_HOST="<database_host>" \
    MYSQL_PORT=3306 \
    MYSQL_USER=kopano \
    MYSQL_PASSWORD=kopano \
    MYSQL_DATABASE=kopano \
    MYSQL_DATABASE_ZPUSH=zpush \
    ATTACHMENT_PATH="attachments" \
    ATTACHMENT_S3_HOSTNAME="" \
	ATTACHMENT_S3_PROTOCOL="http" \
	ATTACHMENT_S3_ACCESS_KEY="" \
	ATTACHMENT_S3_SECRET_ACCESS_KEY="" \
	ATTACHMENT_S3_BUCKET_NAME="kopano-attachments"\
    DISABLED_FEATURES="imap pop3" \
    SMTP_SERVER=localhost \
    SMTP_PORT=25 \
    TIMEZONE="Europe/Berlin" \
    USE_FULLEMAIL_FOR_LOGIN=true \
    THEME=""


ADD templates /srv/templates
ADD scripts /srv/scripts

# install basics
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        gpg \
        gpg-agent \
        jq \
        locales \
        moreutils \
        python3-minimal \
        net-tools \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* \
    && chmod +x /srv/scripts/*

# install apt key if supported kopano
RUN echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
    && echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/webapp:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/files:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://serial:$KOPANO_SERIAL@download.kopano.io/supported/mdm:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
    && echo "deb http://repo.z-hub.io/z-push:/final/$OS_VERSION/ /" >>  /etc/apt/sources.list.d/z-push.list \
    && curl -s -S -o - "https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/$OS_VERSION/Release.key" | apt-key add - \
	&& curl https://repo.z-hub.io/z-push:/final/$OS_VERSION/Release.key | apt-key add -

# Create kopano user and group
RUN groupadd --system --gid ${KOPANO_GID} kopano \
    && useradd --system --shell /usr/sbin/nologin --home /var/lib/kopano --gid ${KOPANO_GID} --uid ${KOPANO_UID} kopano

# Install Dockerize
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz --output /tmp/dockerize.tar.gz  \
	&& tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
	&& rm /tmp/dockerize.tar.gz

# install locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=de_DE.UTF-8

# install kopano  packages
RUN apt update \
    && apt install --no-install-recommends -y \
        kopano-server-packages \
        apache2 \
        php-fpm \
        ca-certificates \
        crudini \
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
        php-mbstring \
        libapache2-mod-php \
        z-push-autodiscover \
        z-push-config-apache \
        z-push-config-apache-autodiscover \
        z-push-kopano \
        z-push-kopano-gabsync \
        z-push-state-sql \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*



# configure php-fpm
RUN mkdir -p /run/php && chown www-data:www-data /run/php \
    && crudini --set /etc/php/7.0/fpm/php.ini PHP upload_max_filesize 500M \
    && crudini --set /etc/php/7.0/fpm/php.ini PHP post_max_size 500M  \
    && crudini --set /etc/php/7.0/fpm/php.ini PHP max_input_vars 1800 \
    && crudini --set /etc/php/7.0/fpm/php.ini Session session.save_path /run/sessions

# configure z-push
RUN mkdir -p /var/lib/z-push /var/log/z-push /srv/plugins \
    && touch /var/log/z-push/z-push-error.log /var/log/z-push/z-push.log \
    && chown www-data:www-data /var/lib/z-push /var/log/z-push /var/log/z-push/*


HEALTHCHECK CMD bash /srv/scripts/healthcheck.sh
ENTRYPOINT ["/srv/scripts/entrypoint.sh"]




