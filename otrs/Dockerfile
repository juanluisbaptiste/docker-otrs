FROM centos:6.6
MAINTAINER Juan Luis Baptiste <juan.baptiste@gmail.com>

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
    supervisor tar which http://ftp.otrs.org/pub/otrs/RPMS/rhel/6/otrs-4.0.7-01.noarch.rpm

COPY run.sh /
RUN chmod 755 /run.sh
#Add configuration file
COPY Config.pm /opt/otrs/docker/defaults/Config.pm.default
#Configure supervisord
RUN sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf
#RUN echo [include] >> /etc/supervisord.conf
#RUN echo 'files = /etc/supervisord.d/*.ini' >> /etc/supervisord.conf
COPY etc/supervisord.d/otrs.ini /etc/supervisord.d/
RUN cat /etc/supervisord.d/otrs.ini >> etc/supervisord.conf

#set up sshd
#RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
#RUN echo "root:root" | chpasswd

#enable crons
#WORKDIR /opt/otrs/var/cron/
#USER otrs
#RUN ls
#RUN "/bin/bash -c 'for foo in *.dist; do cp $foo `basename $foo .dist`; done'"

USER root
EXPOSE 22 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]