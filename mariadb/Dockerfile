FROM centos/mariadb:latest
MAINTAINER "Juan Luis Baptiste" <juan.baptiste@gmail.com>
ENV MYSQL_ROOT_PASSWORD changeme

RUN yum install -y epel-release
COPY run.sh /usr/bin/
RUN chmod 755 /usr/bin/run.sh

#Change db configuration as required by official install docs:
RUN sed -i.bk -r '/^\[mysqld\]$/a max_allowed_packet=20M' /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a query_cache_size=32M' /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a innodb_log_file_size=256M' /etc/my.cnf
#Delete the innodb log file because of the new config parameters

#Enable utf8 support
RUN sed -i.bk -r '/^\[mysqld\]$/a skip-character-set-client-handshake' /etc/my.cnf
RUN sed -i.bk -r "/^\[mysqld\]$/a init_connect='SET collation_connection = utf8_unicode_ci'" /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a collation-server = utf8_general_ci' /etc/my.cnf
RUN sed -i.bk -r "/^\[mysqld\]$/a init-connect=\'SET NAMES utf8\'" /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a character-set-server = utf8' /etc/my.cnf
VOLUME [ "/var/lib/mysql" ]
EXPOSE 3306 22
CMD ["/usr/bin/run.sh"]
