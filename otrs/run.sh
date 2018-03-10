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

. ./functions.sh

if [ "$OTRS_DEBUG" == "yes" ];then
  enable_debug_mode
fi

# while true; do
#   out="`$mysqlcmd -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
#   print_info $out
#   echo "$out" | grep -E "COUNT|Enter" 2>&1 > /dev/null
#   if [ $? -eq 0 ]; then
#     print_info "Server is up !"
#     break
#   fi
#   print_warning "DB server still isn't up, sleeping a little bit ..."
#   sleep 2
# done

wait_for_db
#If OTRS_INSTALL isn't defined load a default install
if [ "$OTRS_INSTALL" != "yes" ]; then
  if [ "$OTRS_INSTALL" == "no" ]; then
    if [ -e "${OTRS_ROOT}var/tmp/firsttime" ]; then
      #Load default install
      print_info "Starting a clean\e[92m OTRS ${OTRS_VERSION} \e[0minstallation ready to be configured !!"
      load_defaults
      #Set default admin user password
      echo -e "Setting password for default admin account root@localhost to: $OTRS_ROOT_PASSWORD"
      ${OTRS_ROOT}bin/otrs.SetPassword.pl --agent root@localhost $OTRS_ROOT_PASSWORD
    fi
  # If OTRS_INSTALL == restore, load the backup files in ${OTRS_ROOT}/backups
  elif [ "$OTRS_INSTALL" == "restore" ];then
    print_info "Restoring OTRS backup: $OTRS_BACKUP_DATE for host ${OTRS_HOSTNAME}"
    restore_backup $OTRS_BACKUP_DATE
  fi
  reinstall_modules
  set_skins
  set_ticker_counter
  set_default_language
  rm -fr ${OTRS_ROOT}var/tmp/firsttime
  #Start OTRS
  ${OTRS_ROOT}bin/otrs.SetPermissions.pl --otrs-user=otrs --web-group=apache ${OTRS_ROOT}
  ${OTRS_ROOT}bin/Cron.sh start otrs
  /usr/bin/perl ${OTRS_ROOT}bin/otrs.Scheduler.pl -w 1
  set_fetch_email_time  
  ${OTRS_ROOT}bin/otrs.RebuildConfig.pl
  ${OTRS_ROOT}bin/otrs.DeleteCache.pl
else
  #If neither of previous cases is true the installer will be run.
  print_info "Starting \e[92m OTRS $OTRS_VERSION \e[0minstaller !!"
fi

#Launch supervisord
echo -e "Starting supervisord..."
supervisord
