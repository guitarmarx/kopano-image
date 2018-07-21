#!/usr/bin/env python
import kopano  # pylint: disable=E0401
import os
import re
import logging
from datetime import datetime, timedelta

# loging
logfile = '/var/log/kopano/spamexport.log'
logging.basicConfig(filename=logfile, level=logging.INFO)

try:

    # parameter
    spamExportPath = "/tmp/spamexport"
    server = kopano.Server()

    # create export folder
    if not os.path.exists(spamExportPath):
        logging.info("create folder " + spamExportPath)
        os.makedirs(spamExportPath)

    # export mail
    for user in server.users(remote=False):
        for item in user.junk:

            # check date
            receivedDate = item.received.strftime("%Y_%m_%d_%H_%M")
            subject = re.sub(r'\W+', '', item.subject)
            fileName = receivedDate + "_" + subject + ".eml"

            now = datetime.now()
            if now-timedelta(hours=24) <= item.received <= now:

                emlfilename = os.path.join(spamExportPath, fileName)
                logging.info("export " + fileName)
                with open(emlfilename, "wb") as fh:
                    fh.write(item.eml())
except Exception as e:
    logging.error(e)
