# MariaDB image for OTRS

This is a preconfigured MariaDB image with the required settings needed for OTRS. The following settings are set on */etc/my.cnf* in the Dockerfile:

    #Change db configuration as required by official install docs:
    max_allowed_packet=20M
    query_cache_size=32M
    innodb_log_file_size=256M

    #Enable utf8 support
    skip-character-set-client-handshake
    init_connect='SET collation_connection = utf8_unicode_ci'
    collation-server = utf8_general_ci
    init-connect='SET NAMES utf8'
    character-set-server = utf8'


### Build instructions

Please see main README.md file.