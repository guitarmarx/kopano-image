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
        -e DB_HOST=<DB_HOST> \
        -e DB_USER=<DB_USER> \
        -e DB_PASS=<DB_PASSWORD> \
        -e DB_NAME=kopano \
        -e DB_NAME_ZPUSH=zpush \
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
        -e SMTP_SERVER=<SMTP_HOST> \
        --hostname <HOSTNAME> \
        -v /etc/localtime:/etc/localtime,ro \
        -v <BASE_PATH>/mailexport/:/tmp/mailexport/ \
        -v <BASE_PATH>/conf/:/etc/kopano/ \
        -v <BASE_PATH>/search/:/var/lib/kopano/search/ \
         -v <BASE_PATH>/attachments/:/var/lib/kopano/attachments \
        <image>:<version>
```
# Configuration
#### Parameters:
Parameter | Function| Default Value|
---|---|---|
DB_HOST|database host|
DB_PORT|database port|3306
DB_NAME|kopano datbase name|kopano
DB_NAME_ZPUSH|z-push datbase name|kopano
DB_USER|database user|kopano
DB_PASS|database password|kopano
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
This image is based on debian:9.6. When build it uses the kopano repository to download the latest version of the following packages:
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
- z-push-kopano (to enable active sync)
- z-push-state-sql
- z-push-kopano-gabsync
#### Spam export
Every day at 01:00 there will be an automatic spam export to **/tmp/spamexport**. Every Mail of the last 24h from every user account will be copied to this to this folder as EML-File. You can persist the folder for further spam evaulation for example to train spam detection.



## Comands

kopano-localize-folders -u <user> --lang de_DE.utf8



