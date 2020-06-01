# Kopano-Image

this docker image deploys kopano based on apache and php
**Note:** You need a `kopano serial key` to build and use kopano.

#### Requirements

To use this kopano image you need a running mta agent like postfix and a running mysql/mariadb database. It it also recommended to use a webproxy like nginx for ssl encryption and https redirection.

Create the following 2 schemata:
```sh
CREATE DATABASE kopano;
CREATE DATABASE zpush;
```

Create a user which access rights to both schemata:
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
        -e MYSQL_HOST=<MYSQL_HOST> \
        -e MYSQL_USER=<MYSQL_USER> \
        -e MYSQL_PASSWORD=<MYSQL_PASSWORD> \
        -e MYSQL_NAME=kopano \
        -e MYSQL_NAME_ZPUSH=zpush \
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
        -e MYSQL_HOST=<MYSQL_HOST> \
        -e MYSQL_USER=<MYSQL_USER> \
        -e MYSQL_PASSWORD=<MYSQL_PASSWORD> \
        -e MYSQL_NAME=kopano \
        -e MYSQL_NAME_ZPUSH=zpush \
        -e SMTP_SERVER=<SMTP_HOST> \
        --hostname <HOSTNAME> \
        -v /etc/localtime:/etc/localtime,ro \
        -v <BASE_PATH>/search/:/var/lib/kopano/search/ \
         -v <BASE_PATH>/attachments/:/var/lib/kopano/attachments \
        <image>:<version>
```
# Configuration
#### Parameters:
Parameter | Function| Default Value|
---|---|---|
SYSTEM_EMAIL|system email address | postmaster@localhost
MYSQL_HOST|database host|
MYSQL_PORT|database port|3306
MYSQL_NAME|kopano datbase name|kopano
MYSQL_NAME_ZPUSH|z-push datbase name|kopano
MYSQL_USER|database user|kopano
MYSQL_PASSWORD|database password|kopano
LOG_LEVEL|log level (1[ERROR] - 6[DEBUG])|3
TIMEZONE|timezone|Europe/Berlin
SMTP_SERVER|used smtp server|
LANG|kopano and system language|de_DE.UTF-8
ATTACHMENT_STORAGE|attachment storage configuaration [database,files, s3]|database
ATTACHMENT_S3_HOSTNAME|when ATTACHMENT_STORAGE=s3, s3 hostname |
ATTACHMENT_S3_PROTOCOL|when ATTACHMENT_STORAGE=s3, s3 access protocol | http
ATTACHMENT_S3_ACCESS_KEY|when ATTACHMENT_STORAGE=s3, s3 access key (user) |
ATTACHMENT_S3_SECRET_ACCESS_KEY|when ATTACHMENT_STORAGE=s3, s3 secret access key (password) |
ATTACHMENT_S3_BUCKET_NAME|when ATTACHMENT_STORAGE=s3, s3 bucket name | kopano-attachments
DISABLED_FEATURES|kopano features|"imap pop3"


#### Ports
 The following ports can be exposed:

Port | Function
--- | --- |
80 |http|
993|imap|
2003|lmtp|
