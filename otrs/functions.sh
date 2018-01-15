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
# files will be loaded from ${OTRS_ROOT}/backups. This means you need to build
# the image with the backup files (sql and Confg.pm) you want to use, or, mount a
# host volume to map where you store the backup files to ${OTRS_ROOT}/backups.
#
# To change the default database and admin interface user passwords you can define
# the following env vars too:
# - OTRS_DB_PASSWORD to set the database password
# - OTRS_ROOT_PASSWORD to set the admin user 'root@localhost' password.
#
. ./util_functions.sh

#Default configuration values
DEFAULT_OTRS_ADMIN_EMAIL="admin@example.com"
DEFAULT_OTRS_ORGANIZATION="Example Company"
DEFAULT_OTRS_SYSTEM_ID="98"
DEFAULT_OTRS_AGENT_LOGO_HEIGHT="67"
DEFAULT_OTRS_AGENT_LOGO_RIGHT="38"
DEFAULT_OTRS_AGENT_LOGO_TOP="4"
DEFAULT_OTRS_AGENT_LOGO_WIDTH="270"
DEFAULT_OTRS_CUSTOMER_LOGO_HEIGHT="50"
DEFAULT_OTRS_CUSTOMER_LOGO_RIGHT="25"
DEFAULT_OTRS_CUSTOMER_LOGO_TOP="2"
DEFAULT_OTRS_CUSTOMER_LOGO_WIDTH="135"
OTRS_BACKUP_DIR="/var/otrs/backups"
OTRS_CONFIG_DIR="${OTRS_ROOT}Kernel/"
OTRS_CONFIG_FILE="${OTRS_CONFIG_DIR}Config.pm"
OTRS_CONFIG_MOUNT_DIR="/Kernel"
OTRS_DATABASE="otrs"

[ -z "${OTRS_INSTALL}" ] && OTRS_INSTALL="no"

mysqlcmd="mysql -uroot -h mariadb -p$MYSQL_ROOT_PASSWORD "

function wait_for_db(){
  while true; do
    out="`$mysqlcmd -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
    print_info $out
    echo "$out" | grep -E "COUNT|Enter" 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
      print_info "Server is up !"
      break
    fi
    print_warning "DB server still isn't up, sleeping a little bit ..."
    sleep 2
  done
}

function create_db(){
  print_info "Creating OTRS database..."
  $mysqlcmd -e "CREATE DATABASE IF NOT EXISTS $OTRS_DATABASE;"
  [ $? -gt 0 ] && print_error "Couldn't create OTRS database !!" && exit 1
  $mysqlcmd -e " GRANT ALL ON otrs.* to 'otrs'@'%' identified by '$OTRS_DB_PASSWORD'";
  [ $? -gt 0 ] && print_error "Couldn't create database user !!" && exit 1
}

function restore_backup(){
  [ -z $1 ] && print_error "\n\e[1;31mERROR:\e[0m OTRS_BACKUP_DATE not set.\n" && exit 1
  #set_variables
  #setup OTRS docker configuration
  setup_otrs_config

  #As this is a restore, drop database first.

  $mysqlcmd -e 'use otrs'
  if [ $? -eq 0  ]; then
    if [ "$OTRS_DROP_DATABASE" == "yes" ]; then
      print_info "OTRS_DROP_DATABASE=\e[92m$OTRS_DROP_DATABASE\e[0m, Dropping existing database\n"
      $mysqlcmd -e 'drop database otrs'
    else
      print_error "Couldn't load OTRS backup, databse already exists !!" && exit 1
    fi
  fi

  create_db
  update_config_value "DatabasePw" $OTRS_DB_PASSWORD


  #Make a copy of installed skins so they aren't overwritten by the backup.
  tmpdir=`mktemp -d`
  [ ! -z $OTRS_AGENT_SKIN ] && cp -rp ${SKINS_PATH}Agent $tmpdir/
  [ ! -z $OTRS_CUSTOMER_SKIN ] && cp -rp ${SKINS_PATH}Customer $tmpdir/
  #Run restore backup command
  ${OTRS_ROOT}scripts/restore.pl -b $OTRS_BACKUP_DIR/$1 -d ${OTRS_ROOT}
  [ $? -gt 0 ] && print_error "Couldn't load OTRS backup !!" && exit 1

  backup_version=`tar -xOf $OTRS_BACKUP_DIR/$1/Application.tar.gz ./RELEASE|grep -o 'VERSION = [^,]*' | cut -d '=' -f2 |tr -d '[[:space:]]'`
  OTRS_INSTALLED_VERSION=`echo $OTRS_VERSION|cut -d '-' -f1`
  print_warning "OTRS version of backup being restored: \e[1;31m$backup_version\e[1;0m"
  print_warning "OTRS version of this container: \e[1;31m$OTRS_INSTALLED_VERSION\e[1;0m"

  check_version $OTRS_INSTALLED_VERSION $backup_version
  if [ $? -eq 0 ]; then
    print_warning "Backup version older than current OTRS version, fixing..."
    #Update version on ${OTRS_ROOT}/RELEASE so it the website shows the correct version.
    sed -i -r "s/(VERSION *= *).*/\1$OTRS_INSTALLED_VERSION/" ${OTRS_ROOT}RELEASE
    print_info "Done."
  fi

  #Restore configured password overwritten by restore
  update_config_value "DatabasePw" $OTRS_DB_PASSWORD

  #Copy back skins over restored files
  [ ! -z $OTRS_CUSTOMER_SKIN ] && cp -rfp $tmpdir/* ${SKINS_PATH} && rm -fr $tmpdir

  #Update the skin preferences  in the users from the backup
  set_users_skin
}

# return 0 if program version is equal or greater than check version
check_version()
{
    local version=$1 check=$2
    local winner=$(echo -e "$version\n$check" | sed '/^$/d' | sort -nr | head -1)
    [[ "$winner" = "$version" ]] && return 0
    return 1
}

function random_string(){
  echo `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
}

function update_config_value(){
  sed  -i -r "s/($Self->\{$1\} *= *).*/\1\"$2\";/" ${OTRS_CONFIG_FILE}
}

function add_config_value(){
  if grep -q "$1" ${OTRS_CONFIG_FILE}
  then
    print_info "Config option already present, skipping..."
  else
    sed -i "/$Self->{Home} = '\/opt\/otrs';/a \
    \$Self->{'$1'} = '$2';" ${OTRS_CONFIG_FILE}
  fi
}

function set_variables(){
  [ -z "${OTRS_HOSTNAME}" ] && OTRS_HOSTNAME="otrs-`random_string`" && print_info "OTRS_HOSTNAME not set, setting hostname to '$OTRS_HOSTNAME'"
  [ -z "${OTRS_ADMIN_EMAIL}" ] && print_info "OTRS_ADMIN_EMAIL not set, setting admin email to '$DEFAULT_OTRS_ADMIN_EMAIL'" && OTRS_ADMIN_EMAIL=$DEFAULT_OTRS_ADMIN_EMAIL
  [ -z "${OTRS_ORGANIZATION}" ] && print_info "OTRS_ORGANIZATION setting organization to '$DEFAULT_OTRS_ORGANIZATION'" && OTRS_ORGANIZATION=$DEFAULT_OTRS_ORGANIZATION
  [ -z "${OTRS_SYSTEM_ID}" ] && print_info "OTRS_SYSTEM_ID not set, setting System ID to '$DEFAULT_OTRS_SYSTEM_ID'"  && OTRS_SYSTEM_ID=$DEFAULT_OTRS_SYSTEM_ID
  [ -z "${OTRS_DB_PASSWORD}" ] && OTRS_DB_PASSWORD=`random_string` && print_info "OTRS_DB_PASSWORD not set, setting password to '$OTRS_DB_PASSWORD'"
  [ -z "${OTRS_ROOT_PASSWORD}" ] && print_info "OTRS_ROOT_PASSWORD not set, setting password to '$DEFAULT_OTRS_PASSWORD'" && OTRS_ROOT_PASSWORD=$DEFAULT_OTRS_PASSWORD

  #Set default skin to use for Agent interface
  [ ! -z "${OTRS_AGENT_SKIN}" ] && print_info "Setting Agent Skin to '$OTRS_AGENT_SKIN'"
  if [ ! -z "${OTRS_AGENT_LOGO}" ]; then
    print_info "Setting Agent Logo to: '$OTRS_AGENT_LOGO'"
    [ -z "${OTRS_AGENT_LOGO_HEIGHT}" ] && print_info "OTRS_AGENT_LOGO_HEIGHT not set, setting default value '$DEFAULT_OTRS_AGENT_LOGO_HEIGHT'" && OTRS_AGENT_LOGO_HEIGHT=$DEFAULT_OTRS_AGENT_LOGO_HEIGHT
    [ -z "${OTRS_AGENT_LOGO_RIGHT}" ] && print_info "OTRS_AGENT_LOGO_RIGHT not set, setting default value '$DEFAULT_OTRS_AGENT_LOGO_RIGHT'" && OTRS_AGENT_LOGO_RIGHT=$DEFAULT_OTRS_AGENT_LOGO_RIGHT
    [ -z "${OTRS_AGENT_LOGO_TOP}" ] && print_info "OTRS_AGENT_LOGO_TOP not set, setting default value '$DEFAULT_OTRS_AGENT_LOGO_TOP'" && OTRS_AGENT_LOGO_TOP=$DEFAULT_OTRS_AGENT_LOGO_TOP
    [ -z "${OTRS_AGENT_LOGO_WIDTH}" ] && print_info "OTRS_AGENT_LOGO_WIDTH not set, setting default value '$DEFAULT_OTRS_AGENT_LOGO_WIDTH'" && OTRS_AGENT_LOGO_WIDTH=$DEFAULT_OTRS_AGENT_LOGO_WIDTH
  fi
  [ ! -z "${OTRS_CUSTOMER_SKIN}" ] && print_info "Setting Customer Skin to '$OTRS_CUSTOMER_SKIN'"
  if [ ! -z "${OTRS_CUSTOMER_LOGO}" ]; then
    print_info "Setting Customer Logo to: '$OTRS_CUSTOMER_LOGO'"
    [ -z "${OTRS_CUSTOMER_LOGO_HEIGHT}" ] && print_info "OTRS_CUSTOMER_LOGO_HEIGHT not set, setting default value '$DEFAULT_OTRS_CUSTOMER_LOGO_HEIGHT'" && OTRS_CUSTOMER_LOGO_HEIGHT=$DEFAULT_OTRS_CUSTOMER_LOGO_HEIGHT
    [ -z "${OTRS_CUSTOMER_LOGO_RIGHT}" ] && print_info "OTRS_CUSTOMER_LOGO_RIGHT not set, setting default value '$DEFAULT_OTRS_CUSTOMER_LOGO_RIGHT'" && OTRS_CUSTOMER_LOGO_RIGHT=$DEFAULT_OTRS_CUSTOMER_LOGO_RIGHT
    [ -z "${OTRS_CUSTOMER_LOGO_TOP}" ] && print_info "OTRS_CUSTOMER_LOGO_TOP not set, setting default value '$DEFAULT_OTRS_CUSTOMER_LOGO_TOP'" && OTRS_CUSTOMER_LOGO_TOP=$DEFAULT_OTRS_CUSTOMER_LOGO_TOP
    [ -z "${OTRS_CUSTOMER_LOGO_WIDTH}" ] && print_info "OTRS_CUSTOMER_LOGO_WIDTH not set, setting default value '$DEFAULT_OTRS_CUSTOMER_LOGO_WIDTH'" && OTRS_CUSTOMER_LOGO_WIDTH=$DEFAULT_OTRS_CUSTOMER_LOGO_WIDTH
  fi
}

function setup_otrs_config(){
  #Check if a host-mounted volume for configuration storage was added to this
  #container
  check_host_mount_dir
  print_info "Updating database password on configuration file..."
  update_config_value "DatabasePw" $OTRS_DB_PASSWORD
  print_info "Updating databse server on configuration file..."
  update_config_value "DatabaseHost" "mariadb"
  print_info "Updating SMTP server on configuration file..."
  add_config_value "SendmailModule::Host" "postfix"
  add_config_value "SendmailModule::Port" "25"
}

function load_defaults(){
  #set_variables
  #Check if a host-mounted volume for configuration storage was added to this
  #container
  setup_otrs_config

  #Add default config options
#   sed -i "/$Self->{'SecureMode'} = 1;/a \
#  \$Self->{'FQDN'} = '$OTRS_HOSTNAME';\
# \n\$Self->{'AdminEmail'} = '$OTRS_ADMIN_EMAIL';\
# \n\$Self->{'Organization'} = '$OTRS_ORGANIZATION';\
# \n\$Self->{'CustomerHeadline'} = '$OTRS_ORGANIZATION';\
# \n\$Self->{'SystemID'} = '$OTRS_SYSTEM_ID';\
# \n\$Self->{'PostMaster::PreFilterModule::NewTicketReject::Sender'} = 'noreply@${OTRS_HOSTNAME}';"\
#  ${OTRS_CONFIG_FILE}

  #Check if database doesn't exists yet (it could if this is a container redeploy)
  $mysqlcmd -e 'use otrs'
  if [ $? -gt 0 ]; then
    create_db

    #Check that a backup isn't being restored
    if [ "$OTRS_INSTALL" == "no" ]; then
      print_info "Loading default db schema..."
      $mysqlcmd otrs < ${OTRS_ROOT}scripts/database/otrs-schema.mysql.sql
      [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database schema !!\n" && exit 1
      print_info "Loading initial db inserts..."
      $mysqlcmd otrs < ${OTRS_ROOT}scripts/database/otrs-initial_insert.mysql.sql
      [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
    fi
  else
    print_warning "otrs database already exists, Ok."
  fi
}

function set_default_language(){
  if [ ! -z $OTRS_LANGUAGE ]; then
    print_info "Setting default language to: \e[92m'$OTRS_LANGUAGE'\e[0m"
    # sed -i "/$Self->{'SecureMode'} = 1;/a \
    # \$Self->{'DefaultLanguage'} = '$OTRS_LANGUAGE';"\
    # ${OTRS_CONFIG_FILE}
    add_config_value "DefaultLanguage" $OTRS_LANGUAGE
 fi
}

function set_ticket_counter() {
  if [ ! -z "${OTRS_TICKET_COUNTER}" ]; then
    print_info "Setting the start of the ticket counter to: \e[92m'$OTRS_TICKET_COUNTER'\e[0m"
    echo "$OTRS_TICKET_COUNTER" > ${OTRS_ROOT}var/log/TicketCounter.log
  fi
  if [ ! -z $OTRS_NUMBER_GENERATOR ]; then
    print_info "Setting ticket number generator to: \e[92m'$OTRS_NUMBER_GENERATOR'\e[0m"
    # sed -i "/$Self->{'SecureMode'} = 1;/a \$Self->{'Ticket::NumberGenerator'} =  'Kernel::System::Ticket::Number::${OTRS_NUMBER_GENERATOR}';"\
    #  ${OTRS_CONFIG_FILE}
    add_config_value "Ticket::NumberGenerator" "Kernel::System::Ticket::Number::${OTRS_NUMBER_GENERATOR}"
  fi
}

function set_skins() {
#   [ ! -z $OTRS_AGENT_SKIN ] &&  sed -i "/$Self->{'SecureMode'} = 1;/a \
# \$Self->{'Loader::Agent::DefaultSelectedSkin'} =  '$OTRS_AGENT_SKIN';\
# \n\$Self->{'Loader::Customer::SelectedSkin'} =  '$OTRS_CUSTOMER_SKIN';"\
#  ${OTRS_CONFIG_FILE}

  [ ! -z $OTRS_AGENT_SKIN ] &&  add_config_value "Loader::Agent::DefaultSelectedSkin" $OTRS_AGENT_SKIN
  [ ! -z $OTRS_AGENT_SKIN ] &&  add_config_value "Loader::Customer::SelectedSkin" $OTRS_CUSTOMER_SKIN
  #Set Agent interface logo
  [ ! -z $OTRS_AGENT_LOGO ] && set_agent_logo

  #Set Customer interface logo
  [ ! -z $OTRS_CUSTOMER_LOGO ] && set_customer_logo
}

function set_users_skin(){
  print_info "Updating default skin for users in backup..."
  $mysqlcmd -e "UPDATE user_preferences SET preferences_value = '$OTRS_AGENT_SKIN' WHERE preferences_key = 'UserSkin'" otrs
  [ $? -gt 0 ] && print_error "Couldn't change default skin for existing users !!\n"
}

function set_agent_logo() {
  set_logo "Agent" $OTRS_AGENT_LOGO_HEIGHT $OTRS_AGENT_LOGO_RIGHT $OTRS_AGENT_LOGO_TOP $OTRS_AGENT_LOGO_WIDTH $OTRS_AGENT_LOGO
}

function set_customer_logo() {
  set_logo "Customer" $OTRS_CUSTOMER_LOGO_HEIGHT $OTRS_CUSTOMER_LOGO_RIGHT $OTRS_CUSTOMER_LOGO_TOP $OTRS_CUSTOMER_LOGO_WIDTH $OTRS_CUSTOMER_LOGO
}

function set_logo () {
  interface=$1
  logo_height=$2
  logo_right=$3
  logo_top=$4
  logo_width=$5
  logo_url=$6

#   sed -i "/$Self->{'SecureMode'} = 1;/a \
#  \$Self->{'${interface}Logo'} =  {\n'StyleHeight' => '${logo_height}px',\
# \n'StyleRight' => '${logo_right}px',\
# \n'StyleTop' => '${logo_top}px',\
# \n'StyleWidth' => '${logo_width}px',\
# \n'URL' => '$logo_url'\n};" ${OTRS_CONFIG_FILE}
  add_config_value "${interface}Logo" "{\n'StyleHeight' => '${logo_height}px',\
 \n'StyleRight' => '${logo_right}px',\
 \n'StyleTop' => '${logo_top}px',\
 \n'StyleWidth' => '${logo_width}px',\
 \n'URL' => '$logo_url'\n};"
}

# function set_customer_logo() {
#   sed -i "/$Self->{'SecureMode'} = 1;/a\$Self->{'CustomerLogo'} =  {\n'StyleHeight' => '${OTRS_CUSTOMER_LOGO_HEIGHT}px',\n'StyleRight' => '${OTRS_CUSTOMER_LOGO_RIGHT}px',\n'StyleTop' => '${OTRS_CUSTOMER_LOGO_TOP}px',\n'StyleWidth' => '${OTRS_CUSTOMER_LOGO_WIDTH}px',\n'URL' => '$OTRS_CUSTOMER_LOGO'\n};" ${OTRS_ROOT}Kernel/Config.pm
# }

function set_fetch_email_time(){
  if [ ! -z $OTRS_POSTMASTER_FETCH_TIME ]; then
    print_info "Setting Postmaster fetch emails time to \e[92m$OTRS_POSTMASTER_FETCH_TIME\e[0m minutes"

    if [ $OTRS_POSTMASTER_FETCH_TIME -eq 0 ]; then

      #Disable email fetching
      sed -i -e '/otrs.PostMasterMailbox.pl/ s/^#*/#/' /var/spool/cron/otrs
    else
      #sed -i -e '/otrs.PostMasterMailbox.pl/ s/^#*//' /var/spool/cron/otrs
      /otrs_postmaster_time.sh $OTRS_POSTMASTER_FETCH_TIME
    fi
  fi
}

function check_host_mount_dir(){
  #Copy the configuration from /Kernel (put there by the Dockerfile) to $OTRS_CONFIG_DIR
  #to be able to use host-mounted volumes. copy only if ${OTRS_CONFIG_DIR} doesn't exist
  if [ "$(ls -A ${OTRS_CONFIG_MOUNT_DIR})" ] && [ ! "$(ls -A ${OTRS_CONFIG_DIR})" ];
  then
    print_info "Found empty \e[92m${OTRS_CONFIG_DIR}\e[0m, copying default configuration to it..."
    mkdir -p ${OTRS_CONFIG_DIR}
    cp -rp ${OTRS_CONFIG_MOUNT_DIR}/* ${OTRS_CONFIG_DIR}
    if [ $? -eq 0 ];
      then
        print_info "Done."
      else
        print_error "Can't move OTRS configuration directory to ${OTRS_CONFIG_DIR}" && exit 1
    fi
  else
    print_info "Found existing configuration directory, Ok."
  fi
  rm -fr ${OTRS_CONFIG_MOUNT_DIR}
}

ERROR_CODE="ERROR"
OK_CODE="OK"
INFO_CODE="INFO"
WARN_CODE="WARNING"

function write_log (){
  message="$1"
  code="$2"

  echo "$[ 1 + $[ RANDOM % 1000 ]]" >> $BACKUP_LOG_FILE
  echo "Status=$code,Message=$message" >> $BACKUP_LOG_FILE
}

function enable_debug_mode (){
  print_info "Preparing debug mode..."
  #DEBIAN_FRONTEND=noninteractive apt-get install -y nmap lsof telnet
  #[ $? -gt 0 ] && print_error "ERROR: Could not intall tools." && exit 1
  print_info "Done."

  set -x
}

function reinstall_modules () {
  print_info "Reinstalling OTRS modules..."
  su -c "$OTRS_ROOT/bin/otrs.Console.pl Admin::Package::ReinstallAll > /dev/null 2>&1> /dev/null 2>&1" -s /bin/bash otrs

  if [ $? -gt 0 ]; then
    print_error "Could not reinstall OTRS modules, try to do it manually with the Package Manager at the admin section."
  else
    print_info "Done."
  fi
}

# SIGTERM-handler
function term_handler () {
 service supervisord stop
 pkill -SIGTERM anacron
 su -c "${OTRS_ROOT}bin/otrs.Daemon.pl stop" -s /bin/bash otrs
 exit 143; # 128 + 15 -- SIGTERM
}
