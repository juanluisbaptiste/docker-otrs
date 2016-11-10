#!/bin/bash
#Backup script. It will make a full backup on a temp directory and then 
#move it to the container's mounted backup directory.
#

TEMP_BACKUP_DIR=`mktemp -d`
OTRS_BACKUP_DIR="/var/otrs/backups"
DEFAULT_BACKUP_TYPE="fullbackup"

function get_current_date(){
   date "+[%d-%m-%Y_%H:%M]"
}

BACKUP_TYPE=$1
[ -z $BACKUP_TYPE ] && BACKUP_TYPE=$DEFAULT_BACKUP_TYPE

echo -e "`get_current_date` Starting OTRS backup for host ${OTRS_HOSTNAME}..."
[ ! -e $TEMP_BACKUP_DIR ] && mkdir -p $TEMP_BACKUP_DIR

/opt/otrs/scripts/backup.pl -d $TEMP_BACKUP_DIR -t $BACKUP_TYPE

if [ $? -eq 0 ]; then
  [ ! -e $OTRS_BACKUP_DIR ] && mkdir -p $OTRS_BACKUP_DIR
  mv $TEMP_BACKUP_DIR/* $OTRS_BACKUP_DIR
  if [ $? -gt 0 ]; then
    echo -e "Backup files move to $OTRS_BACKUP_DIR failed."
    exit 1
  else
    chmod -R 755 $OTRS_BACKUP_DIR
    echo -e "`get_current_date` Backup successful."
  fi
else
  echo -e "Backup failed."
  exit 1
fi

rm -fr $TEMP_BACKUP_DIR