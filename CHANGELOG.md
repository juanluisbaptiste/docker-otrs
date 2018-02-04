# docker-otrs Change Log

## 6.0.4 beta - 2018-02-04
### Added
- New CHANGELOG file with modifications backup to the first OTRS 5.x image.
- Merge PR #24: Added environment variables to allow using an external database server:
  - OTRS_DB_NAME
  - OTRS_DB_USER
  - OTRS_DB_HOST
  - OTRS_DB_PORT
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
- Updated to latest OTRS version 5.0.26.

## 5.0.23 - 2017-09-22
### Added
- New script to automate image rebuild when a new OTRS version is out.

### Changed
- Updated to latest OTRS version 6.0.3.

## 5.0.21 - 2017-07-26
### Changed
- Updated to latest OTRS version 5.0.21.
- Fix Issue #15: Call setup_otrs also on restore.

## 5.0.20 - 2017-06-12
### Changed
- Updated to latest OTRS version 5.0.20.
- Fix sed expressions to replace the database host and password and the smtp server.

## 5.0.18 - 2017-04-10
### Added
- Reinstall modules after an upgrade.
- New environment variable OTRS_DEBUG to print more verbose output while starting up the container.
- New environment variable OTRS_CONFIG_FILE.

### Changed
- Updated to latest OTRS version 5.0.18.
- Fix Issue #15: Call setup_otrs also on restore.

### Removed
- Removed the following environment variables as after they are set these values cannot be updated using _SysConfig_:
  - OTRS_ADMIN_EMAIL
  - OTRS_ORGANIZATION
  - OTRS_SYSTEM_ID

## 5.0.16 - 2017-02-08
### Changed
- Updated to latest OTRS version 5.0.16.

## 5.0.15 - 2017-02-08
### Changed
- Updated to latest OTRS version 5.0.16.
- Added some comments and made some changes to make more clear how to setup the environment variables (Issue #3).
- Update documentation and add information about how to use host-mounted volumes.

## 5.0.14 - 2016-11-10
### Changed
- Updated to latest OTRS version 5.0.14.
- Check for host-mounted data volumes on restore too.
- Update docker-compose files to use host volumes by default.

## 5.0.13 - 2016-10-26
## Added
- Add support for host-mounted volumes: if host-mounted dir exitst and is empty then contents from $OTRS_ROOT/Kernel will be copied to it and symlinked back to /Kernel.

### Changed
- Updated to latest OTRS version 5.0.13.
- By default set PostmasterFollowUpSearchIn* to true.

## 5.0.12 - 2016-08-11
### Changed
- Updated to latest OTRS version 5.0.12.

## 5.0.11 - 2016-06-29
### Changed
- Updated to latest OTRS version 5.0.11.
- Mount /etc/localtime on containers to sync to docker host time.

## 5.0.10 - 2016-06-14
### Changed
- Updated to latest OTRS version 5.0.10.
