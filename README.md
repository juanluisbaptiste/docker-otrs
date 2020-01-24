![OTRS Free](https://raw.githubusercontent.com/juanluisbaptiste/docker-otrs/master/img/logo_otrs6free.png)

# OTRS 6 Ticketing System
[![Docker Build Status](https://img.shields.io/docker/build/juanluisbaptiste/otrs?style=flat-square)](https://hub.docker.com/r/juanluisbaptiste/otrs/build/)
[![Docker Stars](https://img.shields.io/docker/stars/juanluisbaptiste/otrs.svg?style=flat-square)](https://hub.docker.com/r/juanluisbaptiste/otrs/)
[![Docker Pulls](https://img.shields.io/docker/pulls/juanluisbaptiste/otrs.svg?style=flat-square)](https://hub.docker.com/r/juanluisbaptiste/otrs/)

**_Unofficial_**  [OTRS 6 Free](https://community.otrs.com/) docker image. This repository contains the *Dockerfiles* and all other files needed to build and run the container.

We also include a *MariaDB Dockerfile* for a pre-configured image with the [required database settings](http://otrs.github.io/doc/manual/admin/stable/en/html/installation.html).

The OTRS image doesn't include a SMTP service, decoupling applications into multiple containers makes it much easier to scale horizontally and reuse containers. If you don't have access to a SMTP server, you can instead link against this [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix) postfix container.

These images are based on the [official CentOS images](https://registry.hub.docker.com/_/centos/) and
include the latest OTRS version. Older images will be tagged with the OTRS version they run.

_Note:_
* OTRS 5 image sources are still available in [otrs-5_0_x branch](https://github.com/juanluisbaptiste/docker-otrs/tree/otrs-5_0_x).
* OTRS 4 image sources are still available in [otrs-4_0_x branch](https://github.com/juanluisbaptiste/docker-otrs/tree/otrs-4_0_x).

_If you want to follow the development of this project check out [my blog](http://not403.blogspot.com.co/search/label/otrs)._

Table of Contents
=================

   * [OTRS 6 Ticketing System](#otrs-6-ticketing-system)
   * [Table of Contents](#table-of-contents)
      * [Build Instructions](#build-instructions)
      * [How To Run It](#how-to-run-it)
         * [Administration Interface](#administration-interface)
         * [Customer Interface](#customer-interface)
         * [Runtime Configuration](#runtime-configuration)
         * [Custom Configuration File](#custom-configuration-file)
         * [Container auto-start](#container-auto-start)
         * [Changing Default Article Storage Type](#changing-default-article-storage-type)
         * [Docker Secrets](#docker-secrets)
         * [Installing Addons](#installing-addons)
         * [Notes](#notes)
      * [Changing Default Skins](#changing-default-skins)
         * [Custom skin](#custom-skin)
      * [Backups &amp; Restore Procedures](#backups--restore-procedures)
         * [Backup](#backup)
         * [Restore](#restore)
      * [Upgrading](#upgrading)
         * [Minor Version Upgrade](#minor-version-upgrade)
         * [Major Version Upgrade](#major-version-upgrade)
            * [Aditional SQL files](#aditional-sql-files)
            * [XML Configuration Files](#xml-configuration-files)
            * [Add-ons](#add-ons)
            * [Custom Skins &amp; Configuration Files](#custom-skins--configuration-files)
            * [Troubleshooting](#troubleshooting)
      * [Enabling debug mode](#enabling-debug-mode)
      * [Consulting &amp; Support](#consulting--support)



## Build Instructions

We use `docker-compose` to build the images. Clone this repo and then:

    cd docker-otrs
    sudo docker-compose build

This command will build all the images and pull the missing ones like the [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix). This SMTP relay container has its own configuration, you need to specify the environment variables for the SMTP account that will be used to send OTRS email notifications. Please take a look at the [documentation](https://github.com/juanluisbaptiste/docker-postfix).

## How To Run It

The container behavior is controlled by environment variables ([see full list below](#runtime-configuration)). By default, when the container is run it will load a default vanilla OTRS installation (`OTRS_INSTALL=no`) that is ready to be configured as you need. However, you can load a backup or run the installer by defining one of these environment variables:

* `OTRS_INSTALL=restore` Will restore the backup specified by `OTRS_BACKUP_DATE` environment variable. See bellow for more details on backup and restore procedures.
* `OTRS_DROP_DATABASE=yes` Will drop the otrs database it if already exists (by default the container will fail if the database already exists).
* `OTRS_INSTALL=yes` Will run the installer which you can access at:

    http://localhost/otrs/install.pl

If you are running the container remotely, replace *localhost* with the server's hostname. If starting with the default mode (_OTRS__INSTALL=no_), you will need to configure it before starting it. Copy the [`example env file`](https://github.com/juanluisbaptiste/docker-otrs/blob/master/otrs/.env.example) as `.env` on the same directory as the `docker-compose` file and configure it as you need (don't forget to configure the [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix) section at the end). You can then test the service with `docker-compose`:

    sudo docker-compose -f docker-compose-prod.yml up

This will pull and bring up all needed containers, link them and mount volumes according
to the `docker-compose-prod.yml` configuration file. This is a sample output of the boot up process:

![Container boot](https://raw.githubusercontent.com/juanluisbaptiste/docker-otrs/master/img/otrs6_boot_medium.png)

The default database password is `changeme`, to change it, edit the `docker-compose.yml` file and change the
`MYSQL_ROOT_PASSWORD` environment variable on the `mariadb` image definition before
running `docker-compose`.

To start the containers in production mode the the `-d` parameter to the previous command:

    sudo docker-compose -f docker-compose-prod.yml -p companyotrs up -d

After the containers finish starting up you can access the OTRS system at the following
addresses:

### Administration Interface
    http://$OTRS_HOSTNAME/otrs/index.pl

### Customer Interface
    http://$OTRS_HOSTNAME/otrs/customer.pl

### Runtime Configuration

There are also some other environment variables that can be set to customize the default install:

* `OTRS_HOSTNAME` Sets the container's hostname (auto-generated if not defined).
* `OTRS_DB_NAME` Name of database to use. Default is `otrs`.
* `OTRS_DB_HOST` Hostname or IP address of the database server. Default is `mariadb`.
* `OTRS_DB_PORT` Port of the database server. Default is `3306`.
* `OTRS_DB_USER` Database user. Default is `otrs`.
* `OTRS_DB_PASSWORD` otrs user database password. Default password is `changeme`.
* `OTRS_ROOT_PASSWORD` root@localhost user password. Default password is `changeme`.
* `MYSQL_ROOT_USER` Database root user so it can be setup. Default user is `root`.
* `MYSQL_ROOT_PASSWORD` Database root password so it can be setup. Default password is `changeme`.
* `OTRS_SECRETS_FILE` Path to the docker secret file inside the container.
* `OTRS_LANGUAGE` Set the default language for both agent and customer interfaces (For example, "es" for spanish).
* `OTRS_TIMEZONE` to set the default timezone.
* `OTRS_TICKET_COUNTER` Sets the starting point for the ticket counter.
* `OTRS_NUMBER_GENERATOR` Sets the ticket number generator, possible values are : *DateChecksum*, *Date*, *AutoIncrement* or *Random*.
* `OTRS_BACKUP_SCRIPT` Path to a custom backup script to be called by cron by default /etc/cron.d/otrs_backup script. The script must be added by custom image. Default value is /otrs_backup.sh.
* `OTRS_CRON_BACKUP_SCRIPT` Path to a custom backup script to be called by cron. The script must be added by custom image. Default value is /etc/cron.d/otrs_backup.
* `OTRS_ARTICLE_STORAGE_TYPE` Change the article storage type (attachments), possible values are *ArticleStorageFS* and *ArticleStorageDB*. This feature will also move the articles from the database to the filesystem or vice-versa.
* `SHOW_OTRS_LOGO` To disable the OTRS ASCII logo at container startup.
* `OTRS_SENDMAIL_MODULE` Module OTRS should use to send mails (e.g `SMTP`, `SMTPS`, `Sendmail`).
* `OTRS_SMTP_SERVER` Server address of the SMTP server to use.
* `OTRS_SMTP_PORT` Port of the SMTP server to use.
* `OTRS_SMTP_USERNAME` Username to authenticate with.
* `OTRS_SMTP_PASSWORD` Password to authenticate with.

Those environment variables is what you can configure by running the installer for a default install, plus other useful ones.

### Custom Configuration File

You can also add your own _Config.pm_ file configured as you need, by creating a custom image and adding your custom configuration file to _/Kernel/_ (NOT _/opt/otrs/Kernel_), where the container stores OTRS's default configuration files, which are copied back to _/opt/otrs_ on container start, if they have not been already copied and you are using host volumes. This means that configuration files will not be overwritten on container restart. An example _Dockerfile_:

    FROM juanluisbaptiste/otrs:latest
    LABEL maintainer='xxxxxx'

    COPY Config.pm /Kernel

### Changing Default Article Storage Type
The article storage type can be controlled using the `OTRS_ARTICLE_STORAGE_TYPE` environment variable, useful when the database size is getting out of hands so a *filesystem based* storage is better suited. Possible values are *ArticleStorageFS* and *ArticleStorageDB* (this is the default).

This feature will also move the articles from the database to the filesystem or vice-versa as [described in the documentation](https://doc.otrs.com/doc/manual/admin/5.0/en/html/performance-tuning.html#performance-tuning-otrs-storage). If you change the storage type to *ArticleStorageFS* you have to mount */opt/otrs/var/article* directory so exported articles from the database aren't lost at container restart/recreation. The example [docker-compose](https://github.com/juanluisbaptiste/docker-otrs/blob/master/docker-compose.yml) files has this commented out.

### Container auto-start

As a convenience, a pre-made systemd service file `otrs.service` is included as part of the repository to automatically start the container as a host service.

To use it you will need to update `/opt/docker-otrs/docker-compose-prod.yml` to the path to your docker compose file, then copy the service file from the repository to `/usr/lib/systemd/system/`, and run the command `systemctl daemon-reload`. You will then be able to use systemd to control your container.

### Docker Secrets
In order to keep your repositories and images free from any sensitive information you can specify a path to you secrets file to deploy the container easier and safer within a docker swarm/kubernetes environment. You can store any key/value-pair from the list above exactly like the `.env` file.

e.g.
```bash
OTRS_DB_PASSWORD=12345
MYSQL_ROOT_PASSWORD=67890
OTRS_ROOT_PASSWORD=54321
```

And add the path to this secret file (within the container) to `OTRS_SECRETS_FILE`. Docker stores those files in `/run/secrets/`.
```YAML
services:
  otrs:
    environment:
      - OTRS_SECRETS_FILE=/run/secrets/my_otrs_secrets
```

### Installing Addons

To install any addon at container start, map /opt/otrs/addons directory to  a volume and place the /opm files there. The container will install them when starting up.

If you have installed any additional addon, the OTRS container will reinstall them after an upgrade or when a container is removed so they continue working.

### Notes ####
* The included docker-compose file uses `host mounted data containers` to store the database and configuration contents outside the containers. Please take a look at the `docker-compose.yml` file to see the directory mappings and adjust them to your needs.
* Any setting set using the previous environment variables cannot be edited later through the web interface, if you need to change them then you need to update it in your docker-compose/env file and restart your container. The reason for this is that OTRS sets as read-only any setting set on `$OTRS_ROOT/Kernel/Config.pm`.
* For production use there's another `docker-compose` file that points to the pre-built images.

## Changing Default Skins

The default skins and logos for the agent and customer interfaces can be controlled with the following
environment variables:

To set the agent interface skin set `OTRS_AGENT_SKIN` environment variable, for example:

    OTRS_AGENT_SKIN: "ivory"

To set the customer interface skin set `OTRS_CUSTOMER_SKIN` environment variable, for example:

    OTRS_CUSTOMER_SKIN: "ivory"

### Custom skin
If you are adding your own skins, the easiest way is create your own `Dockerfile` inherited from this image and then `COPY` the skin files there. Take a look at the [official documentation](http://doc.otrs.com/doc/manual/developer/stable/en/html/skins.html) on instructions on how to create one. You can also set all the environment variables in there too, for example:

    FROM juanluisbaptiste/otrs:latest
    MAINTAINER Foo Bar <foo@bar.com>
    ENV OTRS_AGENT_SKIN mycompany
    ENV OTRS_AGENT_LOGO skins/Agent/mycompany/img/logo.png
    ENV OTRS_CUSTOMER_LOGO skins/Customer/default/img/logo_customer.png

    COPY skins/ $SKINS_PATH/
    RUN mkdir -p $OTRS_ROOT/Kernel/Config/Files/
    COPY skins/Agent/MyCompanySkin.xml $OTRS_ROOT/Kernel/Config/Files/

## Backups & Restore Procedures

### Backup
By default, automated backups are done daily at 6:00 AM. Backups are compressed using _gzip_ and are stored in */var/otrs/backups*. If you mounted that directory as a host volume then you will have access to the backups files from the docker host server.

You can control the backup behavior with the following variables:

  * `OTRS_BACKUP_TIME`: Sets the backup excecution time, in _cron_ format. If set to _disable_ automated backups will be disabled.
  * `OTRS_BACKUP_TYPE`: Sets the type of backup, it receives the same values as the [OTRS backup script](http://doc.otrs.com/doc/manual/admin/6.0/en/html/backup-and-restore.html):
    * _fullbackup_: Saves the database and the whole OTRS home directory (except /var/tmp and cache directories). This is the default.
    * _nofullbackup_: Saves only the database, /Kernel/Config* and /var directories.
    * _dbonly_: Only the database will be saved.
  * `OTRS_BACKUP_COMPRESSION`: Sets the backup compression method to use, it receives the same values as the [OTRS backup script](http://doc.otrs.com/doc/manual/admin/6.0/en/html/backup-and-restore.html) (gzip|bzip2). The default is gzip.
  * `OTRS_BACKUP_ROTATION`: Sets the number of days to keep the backup files. The default is 30 days.

For example, to change the backup time to database only backups, compress them using _bzip2_ and run twice each day set those variables like this:

    OTRS_BACKUP_TYPE=dbonly
    OTRS_BACKUP_TIME="0 12,12 * * *"
    OTRS_BACKUP_COMPRESSION=bzip2

### Restore

To restore an OTRS backup file (not necessarily created with this container) the following environment variables must be added:

* `OTRS_INSTALL=restore` Will restore the backup specified by `OTRS_BACKUP_DATE`
environment variable.
* `OTRS_BACKUP_DATE` is the backup name to restore. It can have two values:
   - _Uncompressed backup_: A directory with its name in the same *date_time* format that the OTRS backup script uses, for example `OTRS_BACKUP_DATE="2015-05-26_00-32"` with the backup files inside. A backup file created with this image or with any OTRS installation will work (the backup script creates the directory with that name). This feature is useful when migrating from another OTRS install to this container.
   - _Compressed backup file_: A gzip tarball of the previously described directory with the backup files. These tarballs are created by this container when doing a backup.

Backups must be inside the */var/otrs/backups* directory (host mounted by default in the docker-compose file).

 :heavy_exclamation_mark: Remember to remove the _OTRS_INSTALL=restore_ from the docker-compose file environment variables afterwards.

## Upgrading

There are two types of upgrades When upgrading OTRS: _minor_ and _major_ version upgrades. This section describes how to upgrade on each case.

### Minor Version Upgrade

For example from 6.0.1 to 6.0.5, just pull the new image and restart your services:

    sudo docker-compose -f docker-compose-prod.yml pull
    sudo docker-compose -f docker-compose-prod.yml stop
    sudo docker-compose -f docker-compose-prod.yml up -d

### Major Version Upgrade

This upgrade option will do a major version upgrade of OTRS. For example from OTRS 5.0x to 6.0.x. The upgrade process will also upgrade installed packages only from the _official repository_.

To do a major version upgrade, follow these steps:

1. Set the `OTRS_UPGRADE=yes` environment variable in the docker-compose file
2. Replace the current image version tag with the new one on the _image:_ configuration option. For example, change:
```
    image: juanluisbaptiste/otrs:latest-5x
```
  with:
  ```
    image: juanluisbaptiste/otrs:latest
  ```
3. Pull the release image you are upgrading to:
```
    sudo docker-compose -f docker-compose-prod.yml pull
```
4. Restart the containers:
```
    sudo docker-compose -f docker-compose-prod.yml stop
    sudo docker-compose -f docker-compose-prod.yml up -d
```
The upgrade procedure will pause the boot process for 10 seconds to give the user the chance to cancel the upgrade.

The first thing done by the upgrade process is to do a backup of the current version before starting with the upgrade process. Then it will follow the official upgrade instructions (run db upgrade script and upgrade modules, software was updated when pulling the new image). You can use these variables to control the upgrade process:
  * `OTRS_UPGRADE_BACKUP=yes|no` to control if a backup should be done before starting an upgrade (default: yes).

#### Aditional SQL files
Sometimes there are fixes needed to be done to the database when doing an upgrade. When the database upgrade script is executed it will do some inconsistencies checks and it will spit out the sql commands needed to be run to fix the database and continue with the  upgrade process. Map `/opt/otrs/db_upgrade` to a host directory and put the sql files in it, they will get loaded before the database upgrade script is run.

#### XML Configuration Files
Since OTRS 6 the location and XML schema of configuration files has changed. OTRS can try to migrate this configuration files and put them in the new location. For this set `OTRS_UPGRADE_XML_FILES=yes` (default value: `no`).

#### Add-ons
The upgrade process will upgrade official modules (FAQ, Survey, etc). If you have additional 3rd party modules you will need to manually update them in the _Package Manager_.

#### Custom Skins & Configuration Files
As mentioned before, the XML files of custom skins can be migrated to the new location and updated schema setting `OTRS_UPGRADE_XML_FILES=yes`.

#### Troubleshooting ####
 - If after upgrade you can't login with any account, delete the cookies for your OTRS website and try again.
- If you get an 500 error after login it could mean that a module could not be automatically upgraded. Check the container output and look for the messages about modules upgrade.

:heavy_exclamation_mark: Remember to remove the `OTRS_UPGRADE=yes` from the docker-compose file environment variables afterwards.

## Enabling debug mode

If you are having issues starting up the containers you can set `OTRS_DEBUG=yes` to print a more verbose container startup output. It will also install some tools to aid with troubleshooting like _telnet_ and _dig_.

## Consulting & Support

Do you need help setting your OTRS ticketing system or configuring it to match your organization's needs ? I also offer consulting services, drop me a line at: juan _at_ juanbaptiste dot tech
