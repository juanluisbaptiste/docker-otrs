FROM centos/mariadb:latest
MAINTAINER "Juan Luis Baptiste" <juan.baptiste@gmail.com>
ENV MYSQL_ROOT_PASSWORD changeme

RUN yum install -y epel-release
COPY etc/supervisord.d/sshd.ini /etc/supervisord.d/
COPY run.sh /usr/bin/
RUN chmod 755 /usr/bin/run.sh
RUN touch /tmp/firsttime
#RUN sed -i -e "s/^;.*\[include/[include/g" /etc/supervisord.conf 
#RUN sed -i -e "s/^;.*files = relative\/directory/files = supervisord.d/g" /etc/supervisord.conf

RUN sed -i.bk -r '/^\[mysqld\]$/a max_allowed_packet=20M' /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a query_cache_size=32M' /etc/my.cnf
RUN sed -i.bk -r '/^\[mysqld\]$/a innodb_log_file_size=256M' /etc/my.cnf

COPY sql/*.sql /tmp/sql/

VOLUME [ "/var/lib/mysql" ]
EXPOSE 3306 22
CMD ["/usr/bin/run.sh"]
