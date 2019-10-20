#!/bin/bash
set -e

# check processes
ps -C kopano-server || exit 1
ps -C kopano-dagent || exit 1
ps -C kopano-spooler || exit 1
ps -C kopano-gateway || exit 1
ps -C kopano-ical || exit 1
ps -C kopano-search || exit 1
ps -C apache2 || exit 1

# check ports
netstat -plnt | grep ':80' || exit 1
netstat -plnt | grep ':2003' || exit 1


exit 0