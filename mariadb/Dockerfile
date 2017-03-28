FROM centos/mariadb:latest
MAINTAINER "Juan Luis Baptiste" <juan.baptiste@gmail.com>
ENV MYSQL_ROOT_PASSWORD changeme

#mariadb image runs as mysql user (uid 27) but we need to do some configuration
#changes so we need to temporarly switch to root
USER root

#Change db configuration as required by official install docs and Enable utf8 support
RUN sed -i.bk -r '/^\[mysqld\]$/a max_allowed_packet=20M' /etc/my.cnf && \
    sed -i.bk -r '/^\[mysqld\]$/a query_cache_size=32M' /etc/my.cnf && \
    sed -i.bk -r '/^\[mysqld\]$/a innodb_log_file_size=256M' /etc/my.cnf && \
    sed -i.bk -r '/^\[mysqld\]$/a skip-character-set-client-handshake' /etc/my.cnf && \
    sed -i.bk -r "/^\[mysqld\]$/a init_connect='SET collation_connection = utf8_unicode_ci'" /etc/my.cnf && \
    sed -i.bk -r '/^\[mysqld\]$/a collation-server = utf8_general_ci' /etc/my.cnf && \
    sed -i.bk -r "/^\[mysqld\]$/a init-connect=\'SET NAMES utf8\'" /etc/my.cnf && \
    sed -i.bk -r '/^\[mysqld\]$/a character-set-server = utf8' /etc/my.cnf

#Use a separate volume for data.
#VOLUME [ "/var/lib/mysql" ]
#EXPOSE 3306
#Switch to mysql user back
USER 27
#Call launch script
#CMD ["/usr/bin/run.sh"]
