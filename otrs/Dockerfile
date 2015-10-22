#OTRS ticketing system docker image.
FROM centos:6.6
MAINTAINER Juan Luis Baptiste <juan.baptiste@gmail.com>
ENV OTRS_VERSION 4.0.13-01
ENV OTRS_ROOT /opt/otrs/
ENV SKINS_PATH $OTRS_ROOT/var/httpd/htdocs/skins/

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
COPY functions.sh /
RUN chmod 755 /*.sh
#Add configuration file
COPY Config.pm ${OTRS_ROOT}docker/defaults/Config.pm.default
#Add backup script
COPY otrs_backup.sh ${OTRS_ROOT}scripts/
RUN chmod 755 ${OTRS_ROOT}scripts/otrs_backup.sh
#Add change email fetch time script
COPY otrs_postmaster_time.sh ${OTRS_ROOT}scripts/
RUN chmod 755 ${OTRS_ROOT}scripts/otrs_postmaster_time.sh
#Enable mod_filter
RUN sed -i '/filter_module/s/#//g' /etc/httpd/conf/httpd.conf
#reconfigure httpd
RUN sed -i "s/error\/noindex.html/otrs\/index.pl/" /etc/httpd/conf.d/welcome.conf
#Fix pam permissions for crond
RUN echo "+ : otrs : cron crond" |cat >> /etc/security/access.conf
RUN sed -i -e '/pam_loginuid.so/ s/^#*/#/' /etc/pam.d/crond
#Configure supervisord
RUN sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf
COPY etc/supervisord.d/otrs.ini /etc/supervisord.d/
RUN cat /etc/supervisord.d/otrs.ini >> etc/supervisord.conf
#Fix PostmasterFollowUpState config var, this line on Ticket.xml disallow the edition
#of that field through SysConfig
RUN sed -i -e '/<ValidateModule>Kernel::System::SysConfig::StateValidate<\/ValidateModule>/ s/^#*/#/' -i ${OTRS_ROOT}Kernel/Config/Files/Ticket.xml

RUN mkdir -p ${OTRS_ROOT}var/{run,tmp}/
RUN touch ${OTRS_ROOT}var/tmp/firsttime

EXPOSE 80
CMD ["/run.sh"]
