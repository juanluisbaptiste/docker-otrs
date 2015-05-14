#!/bin/bash
# Startup script for this OTRS container. 
#
# The script by default loads a fresh OTRS install ready to be customized through 
# the admin web interface. 
#
# If the environment variable DEFAULT_INSTALL is set to no, then the default web 
# installer can be run from localhost/otrs/installer.pl.
#
# If the environment variable LOAD_BACKUP is set, then the configuration backup 
# files will be loaded from /opt/otrs/docker/backup. This means you need to build 
# the image with the backup files (sql and Confg.pm) you want to use, or, mount a 
# host volume to map where you store the backup files to /opt/otrs/docker/backup.
#
# To change the default database and admin interface user passwords you can define 
# the following env vars too:
# - OTRS_DB_PASSWORD to set the database password
# - OTRS_ROOT_PASSWORD to set the admin user 'root@localhost' password. 
#

DEFAULT_OTRS_PASSWORD="changeme"
DEFAULT_OTRS_ADMIN_EMAIL="admin@example.com"
DEFAULT_OTRS_ORGANIZATION="Example Company"
DEFAULT_OTRS_SYSTEM_ID="98"

[ -z "${LOAD_BACKUP}" ] && LOAD_BACKUP="no"
[ -z "${DEFAULT_INSTALL}" ] && DEFAULT_INSTALL="yes"

[ -z "${OTRS_HOSTNAME}" ] && OTRS_HOSTNAME="otrs-`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1`" && echo "OTRS_ROOT_HOSTNAME not set, setting hostname to '$OTRS_HOSTNAME'"
[ ! -z "${OTRS_ADMIN_EMAIL}" ] && echo "OTRS_ADMIN_EMAIL not set, setting admin email to '$DEFAULT_OTRS_ADMIN_EMAIL'"
[ ! -z "${OTRS_ORGANIZATION}" ] && echo "OTRS_ORGANIZATION setting organization to '$DEFAULT_OTRS_ORGANIZATION'"
[ ! -z "${OTRS_SYSTEM_ID}" ] && echo "OTRS_SYSTEM_ID not set, setting System ID to '$DEFAULT_OTRS_SYSTEM_ID'"
[ -z "${OTRS_DB_PASSWORD}" ] && echo "OTRS_DB_PASSWORD not set, setting password to '$DEFAULT_OTRS_PASSWORD'" && OTRS_DB_PASSWORD=$DEFAULT_OTRS_PASSWORD
[ -z "${OTRS_ROOT_PASSWORD}" ] && echo "OTRS_ROOT_PASSWORD not set, setting password to '$DEFAULT_OTRS_PASSWORD'" && OTRS_ROOT_PASSWORD=$DEFAULT_OTRS_PASSWORD

mysqlcmd="mysql -uroot -h $MARIADB_PORT_3306_TCP_ADDR -p$MARIADB_ENV_MYSQL_ROOT_PASSWORD "

function create_db(){
  echo -e "Creating OTRS database..."
  $mysqlcmd -e "CREATE DATABASE otrs;"
  $mysqlcmd -e "CREATE USER 'otrs'@'%' IDENTIFIED BY '$OTRS_DB_PASSWORD';GRANT ALL PRIVILEGES ON otrs.* TO 'otrs'@'%' WITH GRANT OPTION;"
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't create OTRS database !!\n" && exit 1  
}  

function restore_backup(){
    /opt/otrs/scripts/restore.pl -b /tmp/2015-05-04_17-30/ -d /opt/otrs/
    [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS backup !!\n" && exit 1
}

function load_defaults(){
  create_db
  echo -e "Loading default db schema..."  
  $mysqlcmd otrs < /opt/otrs/scripts/database/otrs-schema.mysql.sql
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database schema !!\n" && exit 1
  echo -e "Loading initial db inserts..."
  $mysqlcmd otrs < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
  echo -e "Copying configuration file: $2"
  cp -f /opt/otrs/docker/defaults/Config.pm.default /opt/otrs/Kernel/Config.pm
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS config file !!\n" && exit 1      
  
  #Add default config options
  sed -i "/$Self->{'SecureMode'} = 1;/a \$Self->{'FQDN'} = '$OTRS_HOSTNAME';\n\$Self->{'AdminEmail'} = '$OTRS_ADMIN_EMAIL';\n\$Self->{'Organization'} = '$OTRS_ORGANIZATION';\n\$Self->{'SystemID'} = '$OTRS_SYSTEM_ID';" /opt/otrs/Kernel/Config.pm
  
}
   
function load_backup(){
  echo -e "Loading SQL file: /opt/otrs/docker/backup/otrs-latest.sql"
  $mysqlcmd otrs < /opt/otrs/docker/backup/otrs-latest.sql
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS SQL file !!\n" && exit 1
  
  echo -e "Copying configuration file: $2"
  cp -f /opt/otrs/docker/backup/Config.pm.latest /opt/otrs/Kernel/Config.pm
  [ $? -gt 0 ] && echo -e "\n\e[1;31mERROR:\e[0m Couldn't load OTRS config file !!\n" && exit 1  
}

while true; do
  out="`$mysqlcmd -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
  if [ $? -eq 0 ]; then
    echo -e "\n\e[92mServer is up !\e[0m\n"
    break
  fi
  echo -e "\nDB server still isn't up, sleeping a little bit ...\n"
  sleep 2
done

#If DEFAULT_INSTALL isn't defined load a default install
if [ "$DEFAULT_INSTALL" == "yes" ]; then
  if [ "$LOAD_BACKUP" != "yes" ]; then
    #Load default install
    load_defaults
    #Set default admin user password
    echo -e "Setting password for default admin account root@localhost..."
    /opt/otrs/bin/otrs.SetPassword.pl --agent root@localhost $OTRS_ROOT_PASSWORD
  # If LOAD_BACKUP is defined load the backup files in /opt/otrs/docker
  elif [ "$LOAD_BACKUP" == "yes" ];then
    load_backup
  fi
  /opt/otrs/bin/Cron.sh start otrs
  /usr/bin/perl /opt/otrs//bin/otrs.Scheduler.pl -w 1
  /opt/otrs/bin/otrs.RebuildConfig.pl
fi
#If neither of previous cases is true the installer will be run.

#Launch supervisord
echo -e "Starting supervisord..."
supervisord