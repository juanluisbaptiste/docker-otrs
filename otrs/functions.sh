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
. ./otrs_ascii_logo.sh

#Default configuration values
DEFAULT_OTRS_ROOT_PASSWORD="changeme"
DEFAULT_OTRS_DB_PASSWORD="changeme"
DEFAULT_MYSQL_ROOT_PASSWORD="changeme"
OTRS_BACKUP_DIR="/var/otrs/backups"
OTRS_CONFIG_DIR="${OTRS_ROOT}Kernel/"
OTRS_CONFIG_FILE="${OTRS_CONFIG_DIR}Config.pm"
OTRS_CONFIG_MOUNT_DIR="/Kernel"
OTRS_DB_PORT=3306
WAIT_TIMEOUT=2
OTRS_ASCII_COLOR_BLUE="38;5;31"
OTRS_ASCII_COLOR_RED="31"

[ -z "${OTRS_INSTALL}" ] && OTRS_INSTALL="no"
[ -z "${OTRS_DB_NAME}" ] && OTRS_DB_NAME="otrs"
[ -z "${OTRS_DB_USER}" ] && OTRS_DB_USER="otrs"
[ -z "${OTRS_DB_HOST}" ] && OTRS_DB_HOST="mariadb"
[ -z "${OTRS_DB_PORT}" ] && OTRS_DB_PORT=3306
[ -z "${SHOW_OTRS_LOGO}" ] && SHOW_OTRS_LOGO="yes"
[ -z "${OTRS_HOSTNAME}" ] && print_info "\e[${OTRS_ASCII_COLOR_BLUE}mOTRS_HOSTNAME\e[0m not set, setting hostname to '${OTRS_HOSTNAME}'" && OTRS_HOSTNAME="otrs-`random_string`"
[ -z "${OTRS_DB_PASSWORD}" ] && print_info "\e[${OTRS_ASCII_COLOR_BLUE}mOTRS_DB_PASSWORD\e[0m not set, setting password to \e[${OTRS_ASCII_COLOR_RED}m${DEFAULT_OTRS_DB_PASSWORD}\e[0m" && OTRS_DB_PASSWORD=${DEFAULT_OTRS_DB_PASSWORD}
[ -z "${OTRS_ROOT_PASSWORD}" ] && print_info "\e[${OTRS_ASCII_COLOR_BLUE}mOTRS_ROOT_PASSWORD\e[0m not set, setting password to \e[${OTRS_ASCII_COLOR_RED}m${DEFAULT_OTRS_ROOT_PASSWORD}\e[0m" && OTRS_ROOT_PASSWORD=${DEFAULT_OTRS_ROOT_PASSWORD}
[ -z "${MYSQL_ROOT_PASSWORD}" ] && print_info "\e[${OTRS_ASCII_COLOR_BLUE}mMYSQL_ROOT_PASSWORD\e[0m not set, setting password to \e[${OTRS_ASCII_COLOR_RED}m${DEFAULT_MYSQL_ROOT_PASSWORD}\e[0m" && MYSQL_ROOT_PASSWORD=${DEFAULT_MYSQL_ROOT_PASSWORD}

mysqlcmd="mysql -uroot -h ${OTRS_DB_HOST} -P ${OTRS_DB_PORT} -p${MYSQL_ROOT_PASSWORD} "

function wait_for_db() {
  while [ ! "$(mysqladmin ping -h ${OTRS_DB_HOST} -P ${OTRS_DB_PORT} -u root \
              --password="${MYSQL_ROOT_PASSWORD}" --silent --connect_timeout=3)" ]; do
    print_info "Database server is not available. Waiting ${WAIT_TIMEOUT} seconds..."
    sleep ${WAIT_TIMEOUT}
  done
  print_info "Database server is up !"
}

function create_db() {
  print_info "Creating OTRS database..."
  $mysqlcmd -e "CREATE DATABASE IF NOT EXISTS ${OTRS_DB_NAME};"
  [ $? -gt 0 ] && print_error "Couldn't create OTRS database !!" && exit 1
  $mysqlcmd -e " GRANT ALL ON ${OTRS_DB_NAME}.* to '${OTRS_DB_USER}'@'%' identified by '${OTRS_DB_PASSWORD}'";
  [ $? -gt 0 ] && print_error "Couldn't create database user !!" && exit 1
}

function restore_backup() {
  [ -z $1 ] && print_error "OTRS_BACKUP_DATE not set." && exit 1
  #Check if a host-mounted volume for configuration storage was added to this
  #container
  check_host_mount_dir
  add_config_value "DatabaseUser" ${OTRS_DB_USER}
  add_config_value "DatabasePw" ${OTRS_DB_PASSWORD}
  add_config_value "DatabaseHost" ${OTRS_DB_HOST}
  add_config_value "DatabasePort" ${OTRS_DB_PORT}

  #Check first that the backup file exists
  restore_file="${OTRS_BACKUP_DIR}/${OTRS_BACKUP_DATE}"
  if [ ! -f ${restore_file} ]; then
    print_error "Backup file does not exist !!" && exit 1
  fi
  #Check file integrity
  if (! tar tf ${restore_file} &> /dev/null) || (! tar xOf ${restore_file} &> /dev/null); then
    print_error "Backup file is corrupt !!" && exit 1
  fi

  #As this is a restore, drop database first.
  $mysqlcmd -e "use ${OTRS_DB_NAME}"
  if [ $? -eq 0  ]; then
    if [ "${OTRS_DROP_DATABASE}" == "yes" ]; then
      print_info "\e[${OTRS_ASCII_COLOR_BLUE}mOTRS_DROP_DATABASE=\e[0m\e[${OTRS_ASCII_COLOR_RED}m${OTRS_DROP_DATABASE}\e[0m, Dropping existing database\n"
      $mysqlcmd -e "drop database ${OTRS_DB_NAME}"
    else
      print_error "Couldn't load OTRS backup, databse already exists !!" && exit 1
    fi
  fi

  create_db
  #Make a copy of installed skins so they aren't overwritten by the backup.
  tmpdir=`mktemp -d`
  [ ! -z $OTRS_AGENT_SKIN ] && cp -rp ${SKINS_PATH}Agent $tmpdir/
  [ ! -z $OTRS_CUSTOMER_SKIN ] && cp -rp ${SKINS_PATH}Customer $tmpdir/
  #Check if OTRS_BACKUP_DIR points to a directory (with the backup file inside) or a
  #backup file.
  if [ -d ${restore_file} ]; then
    restore_dir="${OTRS_BACKUP_DATE}/"
  else
    temp_dir=$(mktemp -d )
    cd ${temp_dir}
    tar zxvf ${restore_file}
    [ $? -gt 0 ] && print_error "Could not uncompress main backup file !!" && exit 1
    cd ..
    restore_dir="$(ls -t ${temp_dir}|head -n1)"
  fi

  restore_dir=${temp_dir}/${restore_dir}
  ${OTRS_ROOT}scripts/restore.pl -b ${restore_dir} -d ${OTRS_ROOT}
  [ $? -gt 0 ] && print_error "Couldn't load OTRS backup !!" && exit 1

  backup_version=`tar -xOf ${restore_dir}/Application.tar.gz ./RELEASE|grep -o 'VERSION = [^,]*' | cut -d '=' -f2 |tr -d '[[:space:]]'`
  [ $? -gt 0 ] && print_error "Couldn't get installed OTRS version !!" && exit 1
  OTRS_INSTALLED_VERSION=`echo $OTRS_VERSION|cut -d '-' -f1`
  print_warning "OTRS version of backup being restored: \e[1;31m$backup_version\e[1;0m"
  print_warning "OTRS version of this container: \e[1;31m$OTRS_INSTALLED_VERSION\e[1;0m"

  check_version ${OTRS_INSTALLED_VERSION} $backup_version
  if [ $? -eq 1 ]; then
    print_warning "Backup version different than current OTRS version, fixing..."
    #Update version on ${OTRS_ROOT}/RELEASE so it the website shows the correct version.
    sed -i -r "s/(VERSION *= *).*/\1${OTRS_INSTALLED_VERSION}/" ${OTRS_ROOT}RELEASE
    print_info "Done."
  fi

  #Restore configured password overwritten by restore
  setup_otrs_config

  #Copy back skins over restored files
  [ ! -z ${OTRS_CUSTOMER_SKIN} ] && cp -rfp ${tmpdir}/* ${SKINS_PATH} && rm -fr ${tmpdir}

  #Update the skin preferences  in the users from the backup
  set_users_skin
}

# return 0 if program version is equal or greater than check version
check_version() {
    local version=$1 check=${2}
    local winner=$(echo -e "$version\n$check" | sed '/^$/d' | sort -nr | head -1)
    [[ "$winner" = "$version" ]] && return 0
    return 1
}

function random_string() {
  echo `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
}

function add_config_value() {
  local key=${1}
  local value=${2}
  #if grep -q "$1" ${OTRS_CONFIG_FILE}
  grep -qE \{\'\?${key}\'\?\} ${OTRS_CONFIG_FILE}
  if [ $? -eq 0 ]
  then
    print_info "Updating configuration option \e[${OTRS_ASCII_COLOR_BLUE}m${key}\e[0m with value: \e[31m${value}\e[0m"
    sed  -i -r "s/($Self->\{*$key*\} *= *).*/\1\"${value}\";/" ${OTRS_CONFIG_FILE}
  else
    print_info "Adding configuration option \e[${OTRS_ASCII_COLOR_BLUE}m${key}\e[0m with value: \e[31m${value}\e[0m"
    sed -i "/$Self->{Home} = '\/opt\/otrs';/a \
    \$Self->{'${key}'} = '${value}';" ${OTRS_CONFIG_FILE}
  fi
}

# Sets default configuration options on $OTRS_ROOT/Kernel/Config.pm. Options set
# here can't be modified via sysConfig later.
function setup_otrs_config() {
  #Set database configuration
  add_config_value "DatabaseUser" ${OTRS_DB_USER}
  add_config_value "DatabasePw" ${OTRS_DB_PASSWORD}
  add_config_value "DatabaseHost" ${OTRS_DB_HOST}
  add_config_value "Database" ${OTRS_DB_NAME}
  #Set general configuration values
  [ ! -z "${OTRS_LANGUAGE}" ] && add_config_value "DefaultLanguage" ${OTRS_LANGUAGE}
  [ ! -z "${OTRS_TIMEZONE}" ] && add_config_value "OTRSTimeZone" ${OTRS_TIMEZONE} && add_config_value "UserDefaultTimeZone" ${OTRS_TIMEZONE}
  add_config_value "FQDN" ${OTRS_HOSTNAME}
  #Set email SMTP configuration
  add_config_value "SendmailModule" "Kernel::System::Email::SMTP"
  add_config_value "SendmailModule::Host" "postfix"
  add_config_value "SendmailModule::Port" "25"
  add_config_value "SecureMode" "1"
}

function load_defaults() {
  #Check if a host-mounted volume for configuration storage was added to this
  #container
  check_host_mount_dir
  check_custom_skins_dir
  #Setup OTRS configuration
  setup_otrs_config

  #Check if database doesn't exists yet (it could if this is a container redeploy)
  $mysqlcmd -e "use ${OTRS_DB_NAME}"
  if [ $? -gt 0 ]; then
    create_db

    #Check that a backup isn't being restored
    if [ "$OTRS_INSTALL" == "no" ]; then
      print_info "Loading default db schemas..."
      $mysqlcmd ${OTRS_DB_NAME} < ${OTRS_ROOT}scripts/database/otrs-schema.mysql.sql
      [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load otrs-schema.mysql.sql schema !!\n" && exit 1
      print_info "Loading initial db inserts..."
      $mysqlcmd ${OTRS_DB_NAME} < ${OTRS_ROOT}scripts/database/otrs-initial_insert.mysql.sql
      [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
      print_info "Loading initial schema constraints..."
      $mysqlcmd ${OTRS_DB_NAME} < ${OTRS_ROOT}scripts/database/otrs-schema-post.mysql.sql
      [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load otrs-schema-post.mysql.sql schema !!\n" && exit 1
    fi
  else
    print_warning "otrs database already exists, Ok."
  fi
}

function set_ticket_counter() {
  if [ ! -z "${OTRS_TICKET_COUNTER}" ]; then
    print_info "Setting the start of the ticket counter to: \e[${OTRS_ASCII_COLOR_BLUE}m'${OTRS_TICKET_COUNTER}'\e[0m"
    echo "${OTRS_TICKET_COUNTER}" > ${OTRS_ROOT}var/log/TicketCounter.log
  fi
  if [ ! -z $OTRS_NUMBER_GENERATOR ]; then
    add_config_value "Ticket::NumberGenerator" "Kernel::System::Ticket::Number::${{OTRS_NUMBER_GENERATOR}}"
  fi
}

function set_skins() {
  if [ ! -z ${OTRS_AGENT_SKIN} ]; then
    add_config_value "Loader::Agent::DefaultSelectedSkin" ${OTRS_AGENT_SKIN}
    print_info "Setting Agent interface custom logo..."
    # Remove AgentLogo option to disable default logo so the skin one is picked up
    sed -i '/AgentLogo/,/;/d' ${OTRS_CONFIG_DIR}/Config/Files/ZZZAAuto.pm
    # Also disable default value of sysconfig so XML/Framework.xml AgentLogo is valid=0 
    $mysqlcmd -e "UPDATE sysconfig_default SET is_valid = 0 WHERE name = 'AgentLogo'" otrs
  fi
  [ ! -z ${OTRS_AGENT_SKIN} ] &&  add_config_value "Loader::Customer::SelectedSkin" ${OTRS_CUSTOMER_SKIN}
}

function set_users_skin() {
  print_info "Updating default skin for users in backup..."
  $mysqlcmd -e "UPDATE user_preferences SET preferences_value = '${OTRS_AGENT_SKIN}' WHERE preferences_key = 'UserSkin'" otrs
  [ $? -gt 0 ] && print_error "Couldn't change default skin for existing users !!\n"
}

function check_host_mount_dir() {
  #Copy the configuration from /Kernel (put there by the Dockerfile) to $OTRS_CONFIG_DIR
  #to be able to use host-mounted volumes. copy only if ${OTRS_CONFIG_DIR} doesn't exist
  if ([ "$(ls -A ${OTRS_CONFIG_MOUNT_DIR})" ] && [ ! "$(ls -A ${OTRS_CONFIG_DIR})" ]) || [ "${OTRS_UPGRADE}" == "yes" ];
  then
    print_info "Found empty \e[${OTRS_ASCII_COLOR_BLUE}m${OTRS_CONFIG_DIR}\e[0m, copying default configuration to it..."
    mkdir -p ${OTRS_CONFIG_DIR}
    cp -rfp ${OTRS_CONFIG_MOUNT_DIR}/* ${OTRS_CONFIG_DIR}
    if [ $? -eq 0 ];
      then
        print_info "Done."
      else
        print_error "Can't move OTRS configuration directory to ${OTRS_CONFIG_DIR}" && exit 1
    fi
  else
    print_info "Found existing configuration directory, Ok."
  fi
}

function check_custom_skins_dir() {
  #Copy the default skins from /skins (put there by the Dockerfile) to $SKINS_PATH
  #to be able to use host-mounted volumes.
  print_info "Copying default skins..."
  mkdir -p ${SKINS_PATH}
  cp -rfp ${OTRS_SKINS_MOUNT_DIR}/* ${SKINS_PATH}
  if [ $? -eq 0 ];
    then
      print_info "Done."
    else
      print_error "Can't copy default skins to ${SKINS_PATH}" && exit 1
  fi
}

ERROR_CODE="ERROR"
OK_CODE="OK"
INFO_CODE="INFO"
WARN_CODE="WARNING"

function write_log () {
  message="$1"
  code="$2"

  echo "$[ 1 + $[ RANDOM % 1000 ]]" >> ${BACKUP_LOG_FILE}
  echo "Status=$code,Message=$message" >> ${BACKUP_LOG_FILE}
}

function enable_debug_mode () {
  print_info "Preparing debug mode..."
  yum install -y telnet dig
  [ $? -gt 0 ] && print_error "ERROR: Could not intall debug tools." && exit 1
  print_info "Done."
  env
  set -x
}

function reinstall_modules () {
  if [ "${OTRS_UPGRADE}" != "yes" ]; then
    print_info "Reinstalling OTRS modules..."
    su -c "$OTRS_ROOT/bin/otrs.Console.pl Admin::Package::ReinstallAll > /dev/null 2>&1" -s /bin/bash otrs

    if [ $? -gt 0 ]; then
      print_error "Could not reinstall OTRS modules, try to do it manually with the Package Manager at the admin section."
    else
      print_info "Done."
    fi
  fi
}

# SIGTERM-handler
function term_handler () {
 service supervisord stop
 pkill -SIGTERM anacron
 su -c "${OTRS_ROOT}bin/otrs.Daemon.pl stop" -s /bin/bash otrs
 exit 143; # 128 + 15 -- SIGTERM
}

function stop_all_services () {
  print_info "Stopping all OTRS services..."
  supervisorctl stop all
  su -c "${OTRS_ROOT}/bin/Cron.sh stop" -s /bin/bash otrs
  su -c "${OTRS_ROOT}/bin/otrs.Daemon.pl stop" -s /bin/bash otrs
}

function start_all_services () {
  print_info "Starting all OTRS services..."
  supervisorctl start all
  su -c "${OTRS_ROOT}/bin/otrs.Daemon.pl start" -s /bin/bash otrs
  su -c "${OTRS_ROOT}/bin/Cron.sh start" -s /bin/bash otrs
}

function upgrade () {
  print_warning "OTRS \e[${OTRS_ASCII_COLOR_BLUE}mMAJOR VERSION UPGRADE\e[0m, press ctrl-C if you want to CANCEL !! (you have 10 seconds)"
  sleep 10

  local version_blacklist="5.0.91\n5.0.92"
  local OTRS_PKG_REPO="https://ftp.otrs.org/pub/otrs/packages/"
  local upgrade_log="/tmp/upgrade.log"
  tmp_dir="/tmp/upgrade/"
  mkdir -p ${tmp_dir}
  echo -e ${version_blacklist} > ${tmp_dir}/blacklist.txt

  print_info "Staring OTRS major version upgrade to version \e[${OTRS_ASCII_COLOR_BLUE}m${OTRS_VERSION}\e[0m..." | tee -a ${upgrade_log}

  # Update configuration files
  check_host_mount_dir
  #Setup OTRS configuration
  setup_otrs_config

  # Backup
  print_info "[*] Backing up container prior to upgrade..." | tee -a ${upgrade_log}
  /otrs_backup.sh &> ${upgrade_log}
  if [ ! $? -eq 143  ]; then
    print_error "Cannot create backup" | tee -a ${upgrade_log} && exit 1
  fi

  # Upgrade database
  print_info "[*] Doing database migration..." | tee -a ${upgrade_log}
  $mysqlcmd -e "use ${OTRS_DB_NAME}"
  if [ $? -eq 0  ]; then
    su -c "/opt/otrs//scripts/DBUpdate-to-6.pl" -s /bin/bash otrs | tee -a ${upgrade_log}
    if [ $? -gt 0  ]; then
      print_error "Cannot migrate database" | tee -a ${upgrade_log} && exit 1
    fi
  fi

  #Update installed packages
  print_info "[*] Updating installed packages..." | tee -a ${upgrade_log}
  su -c "${OTRS_ROOT}/bin/otrs.Console.pl Admin::Package::UpgradeAll" -s /bin/bash otrs &> ${upgrade_log}
  if [ $? -gt 0  ]; then
    print_warning "Cannot upgrade package: ${i}-${latest_version}"  | tee -a ${upgrade_log}
  fi

  rm -fr ${tmp_dir}
  print_info "[*] Major version upgrade finished !!"  | tee -a ${upgrade_log}
}
