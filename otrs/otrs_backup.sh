#!/bin/bash
#Backup script. It will make a full backup on a temp directory and the 
#move it to the container's mounted backup directory.
#

TEMP_BACKUP_DIR=`mktemp -d`
OTRS_BACKUP_DIR="/opt/otrs/backups"

function get_current_date(){
   date "+[%d-%m-%Y_%H:%m]"
}

echo -e "`get_current_date` Staring OTRS backup..."
[ ! -e $TEMP_BACKUP_DIR ] && mkdir -p $TEMP_BACKUP_DIR

/opt/otrs/scripts/backup.pl -d $TEMP_BACKUP_DIR -t fullbackup

if [ $? -eq 0 ]; then
  mv $TEMP_BACKUP_DIR/* $OTRS_BACKUP_DIR
  if [ $? -gt 0 ]; then
    echo -e "Backup files move to $OTRS_BACKUP_DIR failed."
    exit 1
  else
    echo -e "`get_current_date` Backup successful."
  fi
else
  echo -e "Backup failed."
  exit 1
fi

rm -fr $TEMP_BACKUP_DIR