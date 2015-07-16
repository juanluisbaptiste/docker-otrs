#OTRS ticketing system docker image.
FROM centos:6.6
MAINTAINER Juan Luis Baptiste <juan.baptiste@gmail.com>
ENV OTRS_VERSION 4.0.10-01

RUN yum install -y epel-release && \ 
    yum update -y && \
    yum -y install cronie httpd httpd-devel mysql mod_perl \ 
    perl-core "perl(Crypt::SSLeay)" "perl(Net::LDAP)" "perl(URI)" \ 
    procmail "perl(Date::Format)" "perl(LWP::UserAgent)" \ 
    "perl(Net::DNS)" "perl(IO::Socket::SSL)" "perl(XML::Parser)" \ 
    "perl(Apache2::Reload)" "perl(Crypt::Eksblowfish::Bcrypt)" \ 
    "perl(Encode::HanExtra)" "perl(GD)" "perl(GD::Text)" "perl(GD::Graph)" \ 
    "perl(JSON::XS)" "perl(Mail::IMAPClient)" "perl(PDF::API2)" \ 
    "perl(Text::CSV_XS)" "perl(YAML::XS)" "perl(Text::CSV_XS)" "perl(DBD::mysql)" \
    supervisor tar which http://ftp.otrs.org/pub/otrs/RPMS/rhel/6/otrs-${OTRS_VERSION}.noarch.rpm

# Add run script
COPY run.sh /
RUN chmod 755 /run.sh
#Add configuration file
COPY Config.pm /opt/otrs/docker/defaults/Config.pm.default
#Add backup script
COPY otrs_backup.sh /opt/otrs/scripts/
RUN chmod 755 /opt/otrs/scripts/otrs_backup.sh
#Add change email fetch time script
COPY otrs_postmaster_time.sh /opt/otrs/scripts/
RUN chmod 755 /opt/otrs/scripts/otrs_postmaster_time.sh
#Enable mod_filter
RUN sed -i '/filter_module/s/#//g' /etc/httpd/conf/httpd.conf
#reconfigure httpd
RUN sed -i "s/error\/noindex.html/otrs\/index.pl/" /etc/httpd/conf.d/welcome.conf

#Configure supervisord
RUN sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf
COPY etc/supervisord.d/otrs.ini /etc/supervisord.d/
RUN cat /etc/supervisord.d/otrs.ini >> etc/supervisord.conf

#set up sshd
#RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
#RUN echo "root:root" | chpasswd

RUN mkdir -p /opt/otrs/var/tmp/
RUN touch /opt/otrs/var/tmp/firsttime

EXPOSE 80
VOLUME ["/opt/otrs/var"]
VOLUME ["/opt/otrs/Kernel"]
CMD ["/run.sh"]
