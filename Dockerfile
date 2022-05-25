FROM ubuntu:20.04

LABEL maintainer="meteorIT GbR Marcus Kastner"

EXPOSE  2003 143 80

ARG KOPANO_UID=999
ARG KOPANO_GID=999
ARG KOPANO_SERIAL=""
ARG OS_VERSION=Ubuntu_20.04
ARG	DOCKERIZE_VERSION=v0.6.1
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=de_DE.UTF-8 \
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
    SPAM_HEADER="X-Spam-Status" \
    SPAM_VALUE="Yes," \
    SPAM_LEARN_FOLDER=/var/lib/kopano/spamd/spam \
    THEME=""


ADD templates /srv/templates
ADD scripts /srv/scripts

# install basics
RUN apt update && \
    apt install --no-install-recommends -y \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
		cron \
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
RUN echo "deb https://download.kopano.io/supported/core:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
    && echo "deb https://download.kopano.io/supported/webapp:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://download.kopano.io/supported/files:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
	&& echo "deb https://download.kopano.io/supported/mdm:/final/$OS_VERSION/ ./"  >> /etc/apt/sources.list.d/kopano.list \
    && echo "deb https://download.kopano.io/zhub/z-push:/final/$OS_VERSION/ /" >> /etc/apt/sources.list.d/kopano.list \
    && curl -s -S -o - "https://serial:$KOPANO_SERIAL@download.kopano.io/supported/core:/final/$OS_VERSION/Release.key" | apt-key add - \
    && echo "machine download.kopano.io login serial password $KOPANO_SERIAL" > /etc/apt/auth.conf.d/kopano.conf

# Create kopano user and group
RUN groupadd --system --gid ${KOPANO_GID} kopano \
    && useradd --system --shell /usr/sbin/nologin --home /var/lib/kopano --gid ${KOPANO_GID} --uid ${KOPANO_UID} kopano

# Install Dockerize
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz --output /tmp/dockerize.tar.gz  \
	&& tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
	&& rm /tmp/dockerize.tar.gz

# install locales & time
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=$LANG \
    && ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && apt update && apt  install -y tzdata \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* \
    && dpkg-reconfigure --frontend noninteractive tzdata

# install de-locale kopano
RUN apt update \
    && apt-get download kopano-lang \
    && dpkg-deb -R kopano-lang_*.deb   kopano-lang \
    && mv kopano-lang/usr/share/locale/de/LC_MESSAGES/kopano.mo /usr/share/locale/de/LC_MESSAGES/ \
    && rm kopano-lang_*.deb \
    && rm -r kopano-lang \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

# install kopano  packages
RUN apt update  \
    && apt install --no-install-recommends -y  \
        kopano-server-packages \
        kopano-lang \
        libkcoidc-dev \
        apache2 \
        php-fpm \
        crudini \
        kopano-webapp \
        kopano-spamd \
        libapache2-mod-php \
        z-push-config-apache \
        z-push-ipc-sharedmemory \
        z-push-common \
        z-push-backend-kopano \
        z-push-state-sql \
        z-push-kopano-gabsync \
         ca-certificates \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

# install kopano plugins
RUN apt update  \
    && apt install --no-install-recommends -y  \
        kopano-webapp-plugin-files \
        kopano-webapp-plugin-filesbackend-owncloud \
        kopano-webapp-plugin-mdm \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*

RUN phpenmod kopano

# configure php-fpm
RUN mkdir -p /run/php && chown www-data:www-data /run/php \
    && crudini --set /etc/php/7.4/fpm/php.ini PHP upload_max_filesize 500M \
    && crudini --set /etc/php/7.4/fpm/php.ini PHP post_max_size 500M  \
    && crudini --set /etc/php/7.4/fpm/php.ini PHP max_input_vars 1800 \
    && crudini --set /etc/php/7.4/fpm/php.ini Session session.save_path /run/sessions

# configure z-push
RUN mkdir -p /var/lib/z-push /var/log/z-push /srv/plugins \
    && chown www-data:www-data /var/lib/z-push /var/log/z-push


HEALTHCHECK CMD bash /srv/scripts/healthcheck.sh
ENTRYPOINT ["/srv/scripts/entrypoint.sh"]




