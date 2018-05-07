#!/bin/bash
#Backup script. It will make a full backup on a temp directory and then
#move it to the container's mounted backup directory.
#

. ./functions.sh

TEMP_BACKUP_DIR=`mktemp -d`
OTRS_BACKUP_DIR="/var/otrs/backups"
DEFAULT_BACKUP_TYPE="fullbackup"
trap cleanup INT

function get_current_date(){
   date "+%Y-%m-%d_%H_%M"
}

# SIGTERM-handler
function cleanup () {
  echo -e "Cleaning up..."
  rm -fr $TEMP_BACKUP_DIR
  exit 143; # 128 + 15 -- SIGTERM
}

DATE=$(get_current_date)
BACKUP_FILE_NAME="otrs-${DATE}-full.tar.bz2"

BACKUP_TYPE=$1
[ -z $BACKUP_TYPE ] && BACKUP_TYPE=$DEFAULT_BACKUP_TYPE

echo -e "[${DATE}] Starting OTRS backup for host ${OTRS_HOSTNAME}..."
[ ! -e $TEMP_BACKUP_DIR ] && mkdir -p $TEMP_BACKUP_DIR

stop_all_services

/opt/otrs/scripts/backup.pl -d $TEMP_BACKUP_DIR -t $BACKUP_TYPE

if [ $? -eq 0 ]; then
  [ ! -e $OTRS_BACKUP_DIR ] && mkdir -p $OTRS_BACKUP_DIR
  #cd ${TEMP_BACKUP_DIR}
  # As the otrs backup command throws three separate backups in a directory, we
  # compress those files into a single one
  tar zcvf ${BACKUP_FILE_NAME} ${TEMP_BACKUP_DIR}/*
  [ $? -gt 0 ] && echo -e "ERROR: Could not compress final backup tarball." && exit 1

  mv ${BACKUP_FILE_NAME} $OTRS_BACKUP_DIR
  if [ $? -gt 0 ]; then
    echo -e "Backup files move to $OTRS_BACKUP_DIR failed."
    exit 1
  else
    chmod -R 755 $OTRS_BACKUP_DIR
    echo -e "${DATE} Backup successful."
  fi
else
  echo -e "ERROR: Backup process failed."
  exit 1
fi

start_all_services
cleanup
