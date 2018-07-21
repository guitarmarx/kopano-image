#!/bin/sh

# parameter
FROM=$1
TO=$2
SUBJECT=$3
USER=$4
MSG=$5

# defaults
self="${0##*/}"
AUTORESPOND_CC=0
AUTORESPOND_NORECIP=0
TIMELIMIT=$((24*60*60))
BASE_PATH=/var/lib/kopano/autorespond
SENDDB=$BASE_PATH/vacation-$USER.db
SENDDBTMP=$BASE_PATH/vacation-$USER-$$.tmp
LOGFILE=/var/log/kopano/autorespond.log


if [ -r /etc/kopano/autorespond ] ; then
        . /etc/kopano/autorespond
fi

if [ ! -d "$BASE_PATH" ] ; then
        echo  "Created directory $BASE_PATH" >> $LOGFILE
        mkdir -p "$BASE_PATH"
        chmod 750 "$BASE_PATH"

        echo "Moving existing vacation files from /tmp to $BASE_PATH" >> $LOGFILE
        mv -fv /tmp/kopano-vacation-* "$BASE_PATH/"
fi

# DEBUG Log
echo "Prepare mail for autorepond ..." >> $LOGFILE
echo "To:$TO From:$FROM Subject:$SUBJECT " >> $LOGFILE
cat $MSG >> $LOGFILE

# Check whether we want to respond to the message
RESPOND=0
if [ "$AUTORESPOND_NORECIP" = "1" ]; then
    RESPOND=1
elif [ "$AUTORESPOND_BCC" = 1 -a "$MESSAGE_BCC_ME" = "1" ]; then
        RESPOND=1
elif [ "$AUTORESPOND_CC" = "1" -a "$MESSAGE_CC_ME" = "1" ]; then
        RESPOND=1
elif [ "$MESSAGE_TO_ME" = "1" ]; then
        RESPOND=1
fi

if [ $RESPOND -ne 1 ]; then
        exit 0;
fi

# Subject is required
if [ -z "$SUBJECT" ]; then
    SUBJECT="Autoreply";
fi
# not enough parameters
if [ -z "$FROM" -o -z "$TO" -o -z "$USER" -o -z "$MSG" ]; then
    echo "not enough parameters ... autorespond failed" >> $LOGFILE
	exit 0;
fi
if [ ! -f "$MSG" ]; then
	echo "No message file ... autorespond failed" >> $LOGFILE
    exit 0;
fi

# Loop prevention tests
if [ "$FROM" = "$TO" ]; then
	echo "Loop detected ... abort" >> $LOGFILE
    exit 0;
fi

shortto=`echo "$TO" | sed -e 's/\(.*\)@.*/\1/' | tr '[A-Z]' '[a-z]'`
if [ "$shortto" = "mailer-daemon" -o "$shortto" = "postmaster" -o "$shortto" = "root" ]; then
    exit 0;
fi

shortfrom=`echo "$FROM" | sed -e 's/\(.*\)@.*/\1/' | tr '[A-Z]' '[a-z]'`
if [ "$shortfrom" = "mailer-daemon" -o "$shortfrom" = "postmaster" -o "$shortfrom" = "root" ]; then
    exit 0;
fi

# Check if mail was send in last $TIMELIMIT timeframe
TIMESTAMP=`date +%s`
if [ -f "$SENDDB" ]; then
    while read last to; do
        if [ "$TO" != "$to" ]; then
            continue
        fi
        if [ $(($last+$TIMELIMIT)) -ge $TIMESTAMP ]; then
			echo "mail was send in last $TIMELIMIT ... abort" >> $LOGFILE
            exit 0;
        fi
    done < "$SENDDB"
fi

umask 066
grep -v "$TO" "$SENDDB" > "$SENDDBTMP" 2>/dev/null
mv "$SENDDBTMP" "$SENDDB" 2>/dev/null
echo $TIMESTAMP "$TO" >> "$SENDDB" 2>/dev/null



# send message
ssmtp $TO  < $MSG
statuscode=$?

if [ $statuscode -eq 0 ]; then
    echo "mail successfully sent to $FROM" >> $LOGFILE
else
    echo "Could not send mail ... ssmtp failed" >> $LOGFILE
    exit 1
fi