# Kopano-Image

this docker image deploys kopano based on nginx und php-fpm-7.
**Note:** You need a `kopano serial key` to build and use kopano.

#### Requirements

To use this kopano image you need a running mta agent like postfix and a running mysql/mariadb database. It it also recommended to use a webproxy like nginx for ssl encryption and https redirection.

Create the following 2 schemata:
```sh
CREATE DATABASE kopano;
CREATE DATABASE zpush;
```

create a user which access rights to both schemata:
```sh
CREATE USER 'kopano'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON kopano.* TO 'kopano'@'%';
GRANT ALL PRIVILEGES ON zpush.* TO 'kopano'@'%';
```


To use this image you need a running mysql database with user, password and database name. Kopano will create the database schema on startup if it does not already exist. You also need a mta-agent like postfix to use this kopano image.

## Quickstart

#### Build Image
```sh
docker build --build-arg KOPANO_SERIAL=<SERIAL>  -t <image_name>:<image_version>
```
#### Run Container
```sh
docker run -d \
        -p 80:80 \
        -e DB_HOST=<DB_HOST> \
        -e DB_USER=<DB_USER> \
        -e DB_PASS=<DB_PASSWORD> \
        -e DB_NAME=<DB_NAME> \
        -e DOMAIN=<MAIL_DOMAIN> \
        -e SMTP_SERVER=<SMTP_HOST> \
        --hostname <HOSTNAME> \
        <image>:<version>
```

#### Kopano with persistent storage
```sh
docker run -d \
        -p 80:80 \
        -p 993:993 \
        -p 2003:2003 \
        -e DB_HOST=<DB_HOST> \
        -e DB_USER=<DB_USER> \
        -e DB_PASS=<DB_PASSWORD> \
        -e DB_NAME=<DB_NAME> \
        -e DOMAIN=<MAIL_DOMAIN> \
        -e SMTP_SERVER=<SMTP_HOST> \
        --hostname <HOSTNAME> \
        -v /etc/localtime:/etc/localtime,ro \
        -v <BASE_PATH>/mailexport/:/tmp/mailexport/ \
        -v <BASE_PATH>/conf/:/etc/kopano/ \
        -v <BASE_PATH>/search/:/var/lib/kopano/search/ \
        <image>:<version>
```
# Configuration
#### Optional Parameters:
Parameter | Function| Default Value|
---|---|---|
DB_NAME_ZPUSH |zpush database name | zpush
NGINX_API_KEY |uses the nginx amplify agent to monitor the php instance  | -
TIMEZONE|set the timezone|Europe/Berlin
PHP_UPLOAD_MAX_FILESIZE|[upload_max_filesize](http://php.net/manual/de/ini.core.php#ini.upload-max-filesize)| 2030M |
PHP_POST_MAX_SIZE|[post_max_size](http://php.net/manual/de/ini.core.php#ini.post-max-size)| 2040M |
PHP_MEMORY_LIMIT|[memory_limit](http://php.net/manual/de/ini.core.php#ini.memory-limit)| 2048M |
FPM_MAX_CHILDREN|[max_children](http://php.net/manual/en/install.fpm.configuration.php)|40
LANG|Language configuration|de_DE.UTF-8|
LANGUAGE|Language configuration|de_DE:de|
LC_ALL|Language configuration|de_DE.UTF-8|

#### Ports
 The following ports can be exposed:

Port | Function
--- | --- |
80 |http|
993|imap|
2003|lmtp|



#### Kopano Configuration
 To configure kopano, you can use the offical [documentation](https://documentation.kopano.io/). The config files are located under /etc/kopano/.

# Implementation details
This image is based on debian:9.4-slim. When build it uses the kopano repository to download the latest version of the following packages:
- kopano-core
- kopano-webapp
- kopano-files
- kopano-mdm

#### Additional packages:
- kopano-webapp-plugin-filepreviewer
- kopano-webapp-plugin-files
- kopano-webapp-plugin-filesbackend-owncloud
- kopano-webapp-plugin-titlecounter
- kopano-webapp-plugin-quickitems
- kopano-webapp-plugin-folderwidgets
- kopano-webapp-plugin-mdm
- kopano-webapp-plugin-spell-de-de
- kopano-webapp-plugin-spell-en
- kopano-webapp-plugin-webappmanual
- z-push-kopano (to enable active sync)
- z-push-state-sql
#### Spam export
Every day at 01:00 there will be an automatic spam export to **/tmp/spamexport**. Every Mail of the last 24h from every user account will be copied to this to this folder as EML-File. You can persist the folder for further spam evaulation for example to train spam detection.





