![OTRS Free](https://raw.githubusercontent.com/juanluisbaptiste/docker-otrs/master/img/logo_otrs6free.png)

# OTRS 6 Ticketing System
[![Docker Stars](https://img.shields.io/docker/stars/juanluisbaptiste/otrs.svg?style=flat-square)](https://hub.docker.com/r/juanluisbaptiste/otrs/)
[![Docker Pulls](https://img.shields.io/docker/pulls/juanluisbaptiste/otrs.svg?style=flat-square)](https://hub.docker.com/r/juanluisbaptiste/otrs/)

**_Unofficial_**  [OTRS 6 Free](http://www.otrs.com/software/) docker image. This repository contains the *Dockerfiles* and all other files needed to build and run the container.

We also include a *MariaDB Dockerfile* for a pre-configured image with the [required database settings](http://otrs.github.io/doc/manual/admin/stable/en/html/installation.html).

The OTRS image doesn't include a SMTP service, decoupling applications into multiple containers makes it much easier to scale horizontally and reuse containers. If you don't have access to a SMTP server, you can instead link against this [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix) postfix container.

These images are based on the [official CentOS images](https://registry.hub.docker.com/_/centos/) and
include the latest OTRS version. Older images will be tagged with the OTRS version they run.

_Note:_
* OTRS 5 image sources are still available in [otrs-5_0_x branch](https://github.com/juanluisbaptiste/docker-otrs/tree/otrs-5_0_x).
* OTRS 4 image sources are still available in [otrs-4_0_x branch](https://github.com/juanluisbaptiste/docker-otrs/tree/otrs-4_0_x).

_If you want to follow the development of this project check out [my blog](http://not403.blogspot.com.co/search/label/otrs)._

## Build Instructions

We use `docker-compose` to build the images. Clone this repo and then:

    cd docker-otrs
    sudo docker-compose build

This command will build all the images and pull the missing ones like the [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix). This SMTP relay container has its own configuration, you need to specify the environment variables for the SMTP account that will be used to send OTRS email notifications. Please take a look at the [documentation](https://github.com/juanluisbaptiste/docker-postfix).

## How To Run It

By default, when the container is run it will load a default vanilla OTRS installation (`OTRS_INSTALL=no`) that is ready to be configured as you need. However, you can load a backup or run the installer by defining one of these environment variables:

* `OTRS_INSTALL=restore` Will restore the backup specified by `OTRS_BACKUP_DATE` environment variable. See bellow for more details on backup and restore procedures.
* `OTRS_DROP_DATABASE=yes` Will drop the otrs database it if already exists (by default the container will fail if the database already exists).

You need to mount that backups volume from somewhere, it can be from another volume (using *--volumes-from*) or mounting a host volume which contains the backup files.

* `OTRS_INSTALL=yes` Will run the installer which you can access at:

    http://localhost/otrs/install.pl

If you are running the container remotely, replace *localhost* with the server's hostname.

There are also some other environment variables that can be set to customize the default install:

* `OTRS_HOSTNAME` Sets the container's hostname (auto-generated if not defined).
* `OTRS_DB_NAME` Name of database to use. Default is `otrs`.
* `OTRS_DB_HOST` Hostname or IP address of the database server. Default is `mariadb`.
* `OTRS_DB_PORT` Port of the database server. Default is `3306`.
* `OTRS_DB_USER` Database user. Default is `otrs`.
* `OTRS_DB_PASSWORD` otrs user database password. Default password is `changeme`.
* `OTRS_ROOT_PASSWORD` root@localhost user password. Default password is `changeme`.
* `MYSQL_ROOT_PASSWORD` Database root password so it can be setup. Default password is `changeme`.
* `OTRS_LANGUAGE` Set the default language for both agent and customer interfaces (For example, "es" for spanish).
* `OTRS_TIMEZONE` to set the default timezone.
* `OTRS_TICKET_COUNTER` Sets the starting point for the ticket counter.
* `OTRS_NUMBER_GENERATOR` Sets the ticket number generator, possible values are : *DateChecksum*, *Date*, *AutoIncrement* or *Random*.
* `SHOW_OTRS_LOGO` To disable the OTRS ASCII logo at container startup.

Those environment variables is what you can configure by running the installer for a default install, plus other useful ones.

The included docker-compose file uses `host mounted data containers` to store the database and configuration contents outside the containers. Please take a look at the `docker-compose.yml` file to see the directory mappings and adjust them to your needs.

### Notes ####
* Any setting set using the previous environment variables cannot be edited later through the web interface, if you need to change them then you need to update it in your docker-compose/env file and restart your container. The reason for this is that OTRS sets as read-only any setting set on `$OTRS_ROOT/Kernel/Config.pm`.
* Make sure that the directories on the docker host for both OTRS configuration and the MySQL data containers have the correct permissions to be accessed from within the containers. The `volumes/mysql` directory should be owned by the MySQL user (27) and the `volumes/config` directory must be owned by id 500 and group id 48. Before running `docker-compose up` make sure permissions are ok:

    chown 27 volumes/mysql
    chown 500:48 volumes/config

For production use there's another `docker-compose` file that points to the pre-built images (be sure that the _host volume directory permissions are correct_ as described before). Then, after adjusting the [`docker-compose-prod.yml`](https://github.com/juanluisbaptiste/docker-otrs/blob/master/docker-compose-prod.yml) file with the previously described environment variables (don't forget to configure the [SMTP relay](https://github.com/juanluisbaptiste/docker-postfix)), you can test the service with `docker-compose`:

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

## Administration Interface
    http://$OTRS_HOSTNAME/otrs/index.pl

## Customer Interface
    http://$OTRS_HOSTNAME/otrs/customer.pl

## Installing Modules

If you have installed any additional module, the OTRS container will reinstall them after an upgrade or when a container is removed so they continue working.

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
Run `/opt/otrs/scripts/otrs_backup.sh` script to create a full backup that will be copied to */var/otrs/backups*. If you mounted that directory as a host volume then you will have access to the backups files from the docker host server. You can setup a periodic cron job on the host that runs the following command:

    docker exec otrs_container /opt/otrs/scripts/otrs_backup.sh

### Restore

To restore an OTRS backup file (not necesarily created with this container) the following environment variables must be added:

* `OTRS_INSTALL=restore` Will restore the backup specified by `OTRS_BACKUP_DATE`
environment variable.
* `OTRS_BACKUP_DATE` is the backup name to restore, in the same *date_time* format that the OTRS backup
script uses, for example `OTRS_BACKUP_DATE="2015-05-26_00-32"` (This is the notation that the backup script that comes with OTRS uses).

Backups must be inside the */var/otrs/backups* directory (you should host mount it).

## Upgrading

There are two types of upgrades When upgrading OTRS: _minor_ and _major_ version upgrades. This section describes how to upgrade on each case.

### Minor Version

For example from 6.0.1 to 6.0.5, just pull the new image and restart your services:

    sudo docker-compose -f docker-compose-prod.yml pull
    sudo docker-compose -f docker-compose-prod.yml stop
    sudo docker-compose -f docker-compose-prod.yml rm -f -v
    sudo docker-compose -f docker-compose-prod.yml up    

### Major Version - EXPERIMENTAL !!!

This upgrade option will do a major version upgrade of OTRS. For example from OTRS 5.0x to 6.0.x. The upgrade process will also upgrade installed packages from the official repository only.

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
    sudo docker-compose -f docker-compose-prod.yml rm -f -v
    sudo docker-compose -f docker-compose-prod.yml up
```
The upgrade procedure will pause the boot process for 10 seconds to give the user the chance to cancel the upgrade.

The first thing done by the upgrade process is to do a backup of the current version before starting with the upgrade process. Then it will follow the official upgrade instructions (run db upgrade script and upgrade modules, software was updated when pulling the new image).

#### Modules (Add-ons)
The upgrade process will upgrade official modules (FAQ, Survey, etc). If you have aditional 3rd party modules you will need to manually update them in _Package Manager_.

#### Custom Skins & Configuration Files
If you have custom skins or additional XML configuration files you will have to manually update them if needed.

#### Troubleshooting ####
 - If after upgrade you can't login with any account, delete the cookies for your OTRS website and try again.
- If you get an 500 error after login it could mean that a module could not be automatically upgraded. Check the container output and look for the messages about modules upgrade.

Remember to remove the `OTRS_UPGRADE` variable from the docker-compose file afterwards.

## Enabling debug mode

If you are having issues starting up the containers you can set `OTRS_DEBUG=yes` to print a more verbose container startup output. It will also install some tools to aid with troubleshooting like _telnet_ and _dig_.
