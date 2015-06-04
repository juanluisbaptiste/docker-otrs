#!/bin/sh
#
# Modify fetch emails time on crontab. It receives as a parameter the time
# to fetch emails, in minutes.
#

OTRS_POSTMASTER_FETCH_TIME=$1

[ -z $OTRS_POSTMASTER_FETCH_TIME ] && echo -e "Need to pass fetch emails time in minutes." && exit 1

CRONTAB_FILE="/var/spool/cron/otrs"

cp $CRONTAB_FILE "$CRONTAB_FILE.old"

awk '{ if ( $0 ~ /otrs.PostMasterMailbox.pl/ )
        { print "*/'$OTRS_POSTMASTER_FETCH_TIME' * * * * " $6 }
       else { print $0 }
     }' $CRONTAB_FILE.old > $CRONTAB_FILE
sed -i -e "s/# fetch emails every 10 minutes/# fetch emails every $OTRS_POSTMASTER_FETCH_TIME minutes/" $CRONTAB_FILE

exit 0