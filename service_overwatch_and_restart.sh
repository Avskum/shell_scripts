#!/bin/bash
#added by robert masir

PROCESS="spamd";

#mailing stuff
tmp=/tmp/mail-body-`date +%F`;
touch $tmp && chmod 600 $tmp;
#Set up the various headers for sendmail to use
TO='linux@sys.ignum.cz';
CC='';
FROM='effingrobot@dpzconsulting3-vm1.cust.ignum.cz';
SUBJECT='spamd is slacking again';
MIMEVersion='1.0';
CONTENTType="text/html; charset=us-ascii";
#Here write the content of your mail.
BODY="spamd has crashed and restarted at: `date`";

if ps ax | grep -v grep | grep $PROCESS > /dev/null
then
        echo "$PROCESS is running";
else
        echo "$PROCESS is NOT running";
        # change the next line to the command you want to run for restarting:
        /etc/init.d/spamassassin restart;
        echo Sending the mail.;
        echo -e "To: $TO" > $tmp;
        echo -e "Cc: $CC" >> $tmp;
        echo -e "From: $FROM" >> $tmp;
        echo -e "Content-Type: $CONTENTType">>$tmp;
        echo -e "MIME-Version: $MIMEVersion">>$tmp;
        echo -e "Subject: $SUBJECT">>$tmp;
        echo -e "\n">>$tmp;
        echo -e "$BODY">>$tmp;
        /usr/sbin/sendmail -t < $tmp;
        rm -rf $tmp;
fi
