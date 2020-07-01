# docker-otrs Change Log

## 6.0.28 - 2020-06-30
### Changed
- Updated to latest OTRS version 6.0.28 and fixed bad update to this version 
  from May.
- Use a separate configuration file with OTRS mysql recommended settings 
  instead of modifying the configuration file with sed (PR #90).

### Added
- Print all services logs to stdout (issue #71)
- Added new  New env variable OTRS_SET_PERMISSIONS to control running of 
  otrs.SetPermissions.pl (issue #91)

## 6.0.27 - 2020-03-30
### Changed
- Updated to latest OTRS version 6.0.27.
- Run DBUpdate-to-6.pl script when a minor upgrade is detected (Issue #86).

## 5.0.42 - 2020-03-27
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.42.


## 6.0.26 - 2020-03-12
### Changed
- Updated to latest OTRS version 6.0.26.

## 5.0.41 - 2020-03-12
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.41.


## 6.0.25 - 2020-01-19
### Changed
- Updated to latest OTRS version 6.0.25.

## 5.0.40 - 2020-01-19
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.40.


## 6.0.24 - 2019-12-13
### Changed
- Updated to latest OTRS version 6.0.24.

## 5.0.39 - 2019-12-13
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.39.

## 6.0.23 - 2019-11-06
### Added
- New feature: Added new environment variable OTRS_CRON_BACKUP_SCRIPT to change the default script called by cron for periodic backups.
- New feature: Switch article storage type using OTRS_ARTICLE_STORAGE_TYPE=(ArticleStorageDB|ArticleStorageFS) environment variable.
### Changed
- Updated to latest OTRS version 6.0.23.

## 5.0.38 - 2019-11-06
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.38.

## 6.0.22 - 2019-09-30
### Changed
- Updated to latest OTRS version 6.0.22.

## 6.0.21 - 2019-08-31
### Changed
- Updated to latest OTRS version 6.0.21.

## 6.0.20 - 2019-07-19
### Added
- Added example systemd service file to run docker-compose at docker host boot.
### Changed
- Updated to latest OTRS version 6.0.20.

## 6.0.19 - 2019-06-04
### Changed
- Updated to latest OTRS version 6.0.19.

## 5.0.36 - 2019-06-04
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.36.
- Disabled secure mode by default so the container can be configured.

## 6.0.17 - 2019-05-29
### Changed
- Rebuild 6.0.17 with latest container code.

## 6.0.18 - 2019-05-29
### Added
- New feature: Install new addons at container start.
- New feature: load additional sql files before db upgrade during major version upgrade.
- Added new environment variable OTRS_UPGRADE_XML_FILES=(yes|no) to enable migration of XML configuration files during an major version upgrade.
- Merged PR #64 that makes OTRS SMTP configurable.

## 5.0.35 - 2019-05-21
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.35.

## 6.0.18 - 2019-04-19
### Added
- New environment variable OTRS_UPGRADE_BACKUP=(yes|no) to enable/disable automatic
  backup before starting a major version upgrade. Default is yes.
- Merged PR #60 that adds support for docker secrets.
### Changed
- Updated to latest OTRS version 6.0.18.
- Mask root@localhost password at boot.
- Fixed issue #59 by setting LANG and LANGUAGE environment variables on Dockerfile.

## 6.0.17 - 2019-03-12
### Added
- Merged PR #57 that adds a new variable MYSQL_ROOT_USER to configure the database root username.
### Changed
- Updated to latest OTRS version 6.0.17.


## 6.0.16 - 2019-01-29
### Changed
- Fixed mysql database container problem when starting due to running it with an incorrect user.
- Moved to official MariaDB image.

## 6.0.16 - 2019-01-23
### Changed
- Updated to latest OTRS version 6.0.16.

## 5.0.34 - 2019-01-23
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.34.

## 6.0.15 - 2018-12-14
### Changed
- Updated to latest OTRS version 6.0.15.
### Added
- New feature: configurable automatic backups, controlled by environment variables OTRS_BACKUP_TIME, OTRS_BACKUP_TYPE, OTRS_BACKUP_COMPRESSION and OTRS_BACKUP_ROTATION.

## 5.0.33 - 2018-12-14
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.33.

## 6.0.14 - 2018-12-02
### Changed
- Updated to latest OTRS version 6.0.14.

## 5.0.32 - 2018-12-02
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.32.

## 4.0.33 - 2018-12-02
### Changed
- Updated otrs-4_0_x branch to OTRS 4.0.33.

## 6.0.11 - 2018-10-01
### Changed
- Updated to latest OTRS version 6.0.11.

## 5.0.30 - 2018-10-01
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.30.

## 4.0.32 - 2018-10-01
### Changed
- Updated otrs-4_0_x branch to OTRS 4.0.32.

## 6.0.10 - 2018-09-12
### Changed
- Fixed issue #41.

## 6.0.10 - 2018-09-06
### Changed
- Updated to latest OTRS version 6.0.10.
- Improved backups restore documentation.
### Added
- New example env file with all configurable variables and updated README.md.

## 5.0.29 - 2018-09-06
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.29.

## 4.0.31 - 2018-09-06
### Changed
- Updated otrs-4_0_x branch to OTRS 4.0.31.

## 6.0.9 - 2018-07-24
### Changed
- Updated to latest OTRS version 6.0.9.
- improvements in custom skins handling.
### Added
- New environment variable OTRS_TIMEZONE to set the default timezone.

## 6.0.8 - 2018-06-12
### Changed
- Updated to latest OTRS version 6.0.8.

## 5.0.28 - 2018-06-12
### Changed
- Updated otrs-5_0_x branch to OTRS 5.0.28.

## 4.0.30 - 2018-06-12
### Changed
- Updated otrs-4_0_x branch to OTRS 4.0.30.

## 6.0.7 - 2018-05-29
### Added
- Check for backup file integrity before starting the restore backup process (OTRS_INSTALL=restore).

### Changed
- Fix issue #30: Set default passwords for OTRS_DB_PASSWORD, OTRS_ROOT_PASSWORD and MYSQL_ROOT_PASSWORD.

### Removed
- Removed all environment variables for setting a custom logo. Use a custom skin instead.

## 6.0.7 - 2018-05-07
### Added
- New feature: do major version upgrades by setting env var OTRS_UPGRADE=yes.

### Changed
- Updated to latest OTRS version 6.0.7.
- otrs_backup.sh: stop services before doing the backup and starting them again afterwards to avoid random backup failures.

## 5.0.27 - 2018-05-07
### Added
- New feature: backported major version upgrades by setting env var OTRS_UPGRADE=yes.

### Changed
- Backported latest otrs_backup.sh script.

## 4.0.29 - 2018-05-06
### Changed
- Updated branch otrs_4_x to latest OTRS version 4.0.29.


## 6.0.6 - 2018-03-14
### Changed
- Updated to latest OTRS version 6.0.6.
- Improved otrs_backup.sh to handle SIGINT signals (ctrl c) and compress the backup directory into a single .gz file.
- Improved version automatic update script.
- When OTRS_DEBUG is set, also print env command.

## 6.0.5 - 2018-02-13
### Changed
- Updated to latest OTRS version 6.0.5.

## 6.0.4 beta - 2018-02-04
### Added
- Install missing rsyslogd daemon.
- New CHANGELOG file with modifications backup to the first OTRS 5.x image.
- Merge PR #24: Added environment variables to allow using an external database server:
  - OTRS_DB_NAME
  - OTRS_DB_USER
  - OTRS_DB_HOST
  - OTRS_DB_PORT
- New OTRS logo in ASCII displayed at container startup. It can be disable with SHOW_OTRS_LOGO=no.
- When OTRS_DEBUG environment variable is set, some tools like telnet and dig are installed to aid in troubleshooting.

### Changed
- Updated base docker image to CentOS 7.
- Updated to latest OTRS version 6.0.4.
- Upgraded _docker-compose.yml_ files to version _3_.
- Changed test to detect when the database is up and ready to use mysql ping instead of querying a table.
- Decreased image size by 15%.

### Removed
- Removed default _Config.pm_ file, now configuration options are set directly on the included _Config.pm_ file in _/opt/otrs/Kernel_.
- Removed the following environment variables as after they are set these values cannot be updated using _SysConfig_:
  - OTRS_POSTMASTER_FETCH_TIME

## 5.0.26 - 2017-10-13
### Added
- Merge PR #20: Attempt graceful shutdown of all processes

### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.26.

## 5.0.23 - 2017-09-22
### Added
- New script to automate image rebuild when a new OTRS version is out.

### Changed
- Updated branch otrs_5_x to latest OTRS version 6.0.3.

## 5.0.21 - 2017-07-26
### Changed
- Updated to latest OTRS version 5.0.21.
- Fix Issue #15: Call setup_otrs also on restore.

## 5.0.20 - 2017-06-12
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.20.
- Fix sed expressions to replace the database host and password and the smtp server.

## 5.0.18 - 2017-04-10
### Added
- Reinstall modules after an upgrade.
- New environment variable OTRS_DEBUG to print more verbose output while starting up the container.
- New environment variable OTRS_CONFIG_FILE.

### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.18.
- Fix Issue #15: Call setup_otrs also on restore.

### Removed
- Removed the following environment variables as after they are set these values cannot be updated using _SysConfig_:
  - OTRS_ADMIN_EMAIL
  - OTRS_ORGANIZATION
  - OTRS_SYSTEM_ID

## 5.0.16 - 2017-02-08
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.16.

## 5.0.15 - 2017-02-08
### Changed
- Updated to latest OTRS version 5.0.16.
- Added some comments and made some changes to make more clear how to setup the environment variables (Issue #3).
- Update documentation and add information about how to use host-mounted volumes.

## 5.0.14 - 2016-11-10
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.14.
- Check for host-mounted data volumes on restore too.
- Update docker-compose files to use host volumes by default.

## 5.0.13 - 2016-10-26
## Added
- Add support for host-mounted volumes: if host-mounted dir exitst and is empty then contents from $OTRS_ROOT/Kernel will be copied to it and symlinked back to /Kernel.

### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.13.
- By default set PostmasterFollowUpSearchIn* to true.

## 5.0.12 - 2016-08-11
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.12.

## 5.0.11 - 2016-06-29
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.11.
- Mount /etc/localtime on containers to sync to docker host time.

## 5.0.10 - 2016-06-14
### Changed
- Updated branch otrs_5_x to latest OTRS version 5.0.10.
