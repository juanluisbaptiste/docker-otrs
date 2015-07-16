#!/bin/bash
# Startup script for this OTRS container. 
#
# The script by default loads a fresh OTRS install ready to be customized through 
# the admin web interface. 
#
# If the environment variable OTRS_INSTALL is set to yes, then the default web 
# installer can be run from localhost/otrs/installer.pl.
#
# If the environment variable OTRS_INSTALL="restore", then the configuration backup 
# files will be loaded from /opt/otrs/backups. This means you need to build 
# the image with the backup files (sql and Confg.pm) you want to use, or, mount a 
# host volume to map where you store the backup files to /opt/otrs/backups.
#
# To change the default database and admin interface user passwords you can define 
# the following env vars too:
# - OTRS_DB_PASSWORD to set the database password
# - OTRS_ROOT_PASSWORD to set the admin user 'root@localhost' password. 
#
env

DEFAULT_OTRS_ADMIN_EMAIL="admin@example.com"
DEFAULT_OTRS_ORGANIZATION="Example Company"
DEFAULT_OTRS_SYSTEM_ID="98"
OTRS_BACKUP_DIR="/var/otrs/backups"

[ -z "${OTRS_INSTALL}" ] && OTRS_INSTALL="no"

mysqlcmd="mysql -uroot -h $MARIADB_PORT_3306_TCP_ADDR -p$MARIADB_ENV_MYSQL_ROOT_PASSWORD "

function create_db(){
  echo -e "Creating OTRS database..."
  $mysqlcmd -e "CREATE DATABASE IF NOT EXISTS otrs;"
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't create OTRS database !!\n" && exit 1
  $mysqlcmd -e " GRANT ALL ON otrs.* to 'otrs'@'%' identified by '$OTRS_DB_PASSWORD'";
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't create database user !!\n" && exit 1
}  

function restore_backup(){
  [ -z $1 ] && echo -e "\n\e[1;31mERROR:\e[0m OTRS_BACKUP_DATE not set.\n" && exit 1
  set_variables
  copy_default_config
  create_db
  update_config_password $OTRS_DB_PASSWORD
  
  #Run restore backup command
  /opt/otrs/scripts/restore.pl -b $OTRS_BACKUP_DIR/$1 -d /opt/otrs/
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS backup !!\n" && exit 1
  
  #Restore configured password overwritten by restore
  update_config_password $OTRS_DB_PASSWORD
}

function random_string(){
  echo `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1`
}

function update_config_password(){
  #Change database password on configuration file
  sed  -i "s/\($Self->{'DatabasePw'} *= *\).*/\1'$1';/" /opt/otrs/Kernel/Config.pm
}

function copy_default_config(){
  echo -e "Copying configuration file..."
  cp -f /opt/otrs/docker/defaults/Config.pm.default /opt/otrs/Kernel/Config.pm
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS config file !!\n" && exit 1
}

function set_variables(){
  [ -z "${OTRS_HOSTNAME}" ] && OTRS_HOSTNAME="otrs-`random_string`" && echo "OTRS_ROOT_HOSTNAME not set, setting hostname to '$OTRS_HOSTNAME'"
  [ -z "${OTRS_ADMIN_EMAIL}" ] && echo "OTRS_ADMIN_EMAIL not set, setting admin email to '$DEFAULT_OTRS_ADMIN_EMAIL'" && OTRS_ADMIN_EMAIL=$DEFAULT_OTRS_ADMIN_EMAIL
  [ -z "${OTRS_ORGANIZATION}" ] && echo "OTRS_ORGANIZATION setting organization to '$DEFAULT_OTRS_ORGANIZATION'" && OTRS_ORGANIZATION=$DEFAULT_OTRS_ORGANIZATION
  [ -z "${OTRS_SYSTEM_ID}" ] && echo "OTRS_SYSTEM_ID not set, setting System ID to '$DEFAULT_OTRS_SYSTEM_ID'"  && OTRS_SYSTEM_ID=$DEFAULT_OTRS_SYSTEM_ID
  [ -z "${OTRS_DB_PASSWORD}" ] && OTRS_DB_PASSWORD=`random_string` && echo "OTRS_DB_PASSWORD not set, setting password to '$OTRS_DB_PASSWORD'"
  [ -z "${OTRS_ROOT_PASSWORD}" ] && echo "OTRS_ROOT_PASSWORD not set, setting password to '$DEFAULT_OTRS_PASSWORD'" && OTRS_ROOT_PASSWORD=$DEFAULT_OTRS_PASSWORD
}

function load_defaults(){
  set_variables
  copy_default_config
  update_config_password $OTRS_DB_PASSWORD
  
  #Add default config options
  sed -i "/$Self->{'SecureMode'} = 1;/a \$Self->{'FQDN'} = '$OTRS_HOSTNAME';\n\$Self->{'AdminEmail'} = '$OTRS_ADMIN_EMAIL';\n\$Self->{'Organization'} = '$OTRS_ORGANIZATION';\n\$Self->{'SystemID'} = '$OTRS_SYSTEM_ID';" /opt/otrs/Kernel/Config.pm

  #Check if database doesn't exists yet (it could if this is a container redeploy)
  $mysqlcmd -e 'use otrs'
  if [ $? -gt 0 ]; then
    create_db
    #Check that a backup isn't being restored
    if [ "$OTRS_INSTALL" == "no" ]; then
      echo -e "Loading default db schema..."
      $mysqlcmd otrs < /opt/otrs/scripts/database/otrs-schema.mysql.sql
      [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database schema !!\n" && exit 1
      echo -e "Loading initial db inserts..."
      $mysqlcmd otrs < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql
      [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
    fi
  fi
}

function set_fetch_email_time(){
  if [ ! -z $OTRS_POSTMASTER_FETCH_TIME ]; then
    echo -e "Setting Postmaster fetch emails time to \e[92m$OTRS_POSTMASTER_FETCH_TIME\e[0m minutes"

    if [ $OTRS_POSTMASTER_FETCH_TIME -eq 0 ]; then

      #Disable email fetching
      sed -i -e '/otrs.PostMasterMailbox.pl/ s/^#*/#/' /var/spool/cron/otrs
    else
      #sed -i -e '/otrs.PostMasterMailbox.pl/ s/^#*//' /var/spool/cron/otrs
      /opt/otrs/scripts/otrs_postmaster_time.sh $OTRS_POSTMASTER_FETCH_TIME
    fi
  fi
}

while true; do
  out="`$mysqlcmd -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
  echo -e $out
  echo "$out" | grep "COUNT"
  if [ $? -eq 0 ]; then
    echo -e "\n\e[92mServer is up !\e[0m\n"
    break
  fi
  echo -e "\nDB server still isn't up, sleeping a little bit ...\n"
  sleep 2
done

#If OTRS_INSTALL isn't defined load a default install
if [ "$OTRS_INSTALL" != "yes" ]; then
  if [ "$OTRS_INSTALL" == "no" ]; then
    if [ -e "/opt/otrs/var/tmp/firsttime" ]; then
      #Load default install
      echo -e "\n\e[92mStarting a clean\e[0m OTRS $OTRS_VERSION \e[92minstallation ready to be configured !!\n\e[0m"
      load_defaults
      #Set default admin user password
      echo -e "Setting password for default admin account root@localhost..."
      /opt/otrs/bin/otrs.SetPassword.pl --agent root@localhost $OTRS_ROOT_PASSWORD
      rm -fr /opt/otrs/var/tmp/firsttime
    fi
  # If OTRS_INSTALL == restore, load the backup files in /opt/otrs/backups
  elif [ "$OTRS_INSTALL" == "restore" ];then
    echo -e "\n\e[92mRestoring \e[0m OTRS \e[92m backup: \n\e[0m"
    restore_backup $OTRS_BACKUP_DATE
  fi
  #Start OTRS
  /opt/otrs/bin/Cron.sh start otrs
  /usr/bin/perl /opt/otrs//bin/otrs.Scheduler.pl -w 1
  set_fetch_email_time  
  /opt/otrs/bin/otrs.RebuildConfig.pl
else
  #If neither of previous cases is true the installer will be run.
  echo -e "\n\e[92mStarting \e[0m OTRS $OTRS_VERSION \e[92minstaller !!\n\e[0m"
fi

#Launch supervisord
echo -e "Starting supervisord..."
supervisord