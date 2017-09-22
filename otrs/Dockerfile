#OTRS ticketing system docker image.
FROM centos:6.6
MAINTAINER Juan Luis Baptiste <juan.baptiste@gmail.com>
ENV OTRS_VERSION=5.0.23-01
ENV OTRS_ROOT "/opt/otrs/"
ENV OTRS_BACKUP_DIR "/var/otrs/backups"
ENV OTRS_CONFIG_DIR "${OTRS_ROOT}Kernel"
ENV OTRS_CONFIG_MOUNT_DIR "/config/"
ENV SKINS_PATH "${OTRS_ROOT}/var/httpd/htdocs/skins/"

RUN yum install -y epel-release && \
    yum update -y && \
    yum -y install cronie httpd httpd-devel mysql mod_perl \
    perl-core "perl(Crypt::SSLeay)" "perl(Net::LDAP)" "perl(URI)" \
    procmail "perl(Date::Format)" "perl(LWP::UserAgent)" \
    "perl(Net::DNS)" "perl(IO::Socket::SSL)" "perl(XML::Parser)" \
    "perl(Apache2::Reload)" "perl(Crypt::Eksblowfish::Bcrypt)" \
    "perl(Encode::HanExtra)" "perl(GD)" "perl(GD::Text)" "perl(GD::Graph)" \
    "perl(JSON::XS)" "perl(Mail::IMAPClient)" "perl(PDF::API2)" "perl(DateTime)" \
    "perl(Text::CSV_XS)" "perl(YAML::XS)" "perl(Text::CSV_XS)" "perl(DBD::mysql)" \
    supervisor tar which && \
    yum install -y http://ftp.otrs.org/pub/otrs/RPMS/rhel/6/otrs-${OTRS_VERSION}.noarch.rpm

# Add scripts and function files
COPY *.sh /
#Add configuration file
COPY Config.pm ${OTRS_ROOT}docker/defaults/Config.pm.default
#Supervisord configuration
COPY etc/supervisord.d/otrs.ini /etc/supervisord.d/
#Fix scripts permissions
#Enable mod_filter & reconfigure httpd
#Fix pam permissions for crond
#Fix PostmasterFollowUpState config var, this line on Ticket.xml disallow the edition
#of that field through SysConfig
RUN chmod 755 /*.sh && \
    sed -i '/filter_module/s/#//g' /etc/httpd/conf/httpd.conf && \
    sed -i "s/error\/noindex.html/otrs\/index.pl/" /etc/httpd/conf.d/welcome.conf && \
    echo "+ : otrs : cron crond" |cat >> /etc/security/access.conf && \
    sed -i -e '/pam_loginuid.so/ s/^#*/#/' /etc/pam.d/crond && \
    sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf && \
    cat /etc/supervisord.d/otrs.ini >> etc/supervisord.conf && \
    sed -i -e '/<ValidateModule>Kernel::System::SysConfig::StateValidate<\/ValidateModule>/ s/^#*/#/' -i ${OTRS_ROOT}Kernel/Config/Files/Ticket.xml && \
    mkdir -p ${OTRS_ROOT}var/{run,tmp}/ && \
    touch ${OTRS_ROOT}var/tmp/firsttime
#To be able to use a host-mounted volume for OTRS configuration we need to move
#away the contents of ${OTRS_CONFIG_DIR} to another place and move them back
#on first container run (see check_host_mount_dir on functions.sh), after the
#host-volume is mounted.
RUN mv ${OTRS_CONFIG_DIR} /

EXPOSE 80
CMD ["/run.sh"]
