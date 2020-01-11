#OTRS ticketing system docker image.
FROM centos:7
MAINTAINER Pedro Henrique <pedro@jac.bsb.br>
ENV OTRS_VERSION=6.0.24-01
ENV OTRS_ROOT "/opt/otrs/"
ENV OTRS_BACKUP_DIR "/var/otrs/backups"
ENV OTRS_CONFIG_DIR "${OTRS_ROOT}Kernel"
ENV OTRS_CONFIG_MOUNT_DIR "/config/"
ENV OTRS_SKINS_MOUNT_DIR "/skins/"
ENV SKINS_PATH "${OTRS_ROOT}/var/httpd/htdocs/skins/"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN yum install -y yum-plugin-fastestmirror && \
    yum install -y epel-release && \
    yum update -y && \
    yum -y install bzip2 cronie httpd mysql mod_perl \
    perl-core procmail \
    rsyslog supervisor tar which && \
    yum -y install cpanm gcc perl perl-App-cpanminus perl-Config-Tiny && \
    cpanm install Crypt::SSLeay ; \
    cpanm install Net::LDAP ; \
    cpanm install Net::SMTP ; \
    cpanm install URI ; \
    cpanm install Date::Format ; \
    cpanm install LWP::UserAgent ; \
    cpanm install Net::DNS ; \
    cpanm install IO::Socket::SSL ; \
    cpanm install XML::Parser ; \
    cpanm install Apache2::Reload ; \
    cpanm install Authen::NTLM ; \
    cpanm install Crypt::Eksblowfish::Bcrypt ; \
    cpanm install Encode::HanExtra ; \
    cpanm install GD ; \
    cpanm install GD::Text ; \
    cpanm install GD::Graph ; \
    cpanm install JSON::XS ; \
    cpanm install Mail::IMAPClient ; \
    cpanm install PDF::API2 ; \
    cpanm install DateTime ; \
    cpanm install Text::CSV_XS ; \
    cpanm install YAML::XS ; \
    cpanm install Text::CSV_XS ; \
    cpanm install DBD::mysql ; \
    yum install -y http://ftp.otrs.org/pub/otrs/RPMS/rhel/7/otrs-${OTRS_VERSION}.noarch.rpm && \
    /opt/otrs/bin/otrs.CheckModules.pl && \
    yum clean all
# Add scripts and function files
COPY *.sh /
#Supervisord configuration
COPY etc/supervisord.d/otrs.ini /etc/supervisord.d/
RUN chmod 755 /*.sh  && \
    cp ${OTRS_ROOT}/var/httpd/htdocs/index.html /var/www/html && \
    chmod 644 /var/www/html/index.html && \
    sed -i 's/\bindex.html\b/& index.pl/' /etc/httpd/conf/httpd.conf && \
    echo "+ : otrs : cron crond" |cat >> /etc/security/access.conf                && \
    sed -i -e '/pam_loginuid.so/ s/^#*/#/' /etc/pam.d/crond                       && \
    sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf && \
    cat /etc/supervisord.d/otrs.ini >> etc/supervisord.conf && \
    sed -i -e '/<ValidateModule>Kernel::System::SysConfig::StateValidate<\/ValidateModule>/ s/^#*/#/' \
        ${OTRS_ROOT}Kernel/Config/Files/XML/Ticket.xml  && \
    mkdir -p ${OTRS_ROOT}var/{run,tmp}/ && \
    perl -cw ${OTRS_ROOT}bin/cgi-bin/index.pl && \
    perl -cw ${OTRS_ROOT}bin/cgi-bin/customer.pl && \
    perl -cw ${OTRS_ROOT}bin/otrs.Console.pl && \
    sed -i -e '/\$ModLoad imjournal/ s/^#*/#/' /etc/rsyslog.conf && \
    sed -i -e '/\$IMJournalStateFile imjournal.state/ s/^#*/#/' /etc/rsyslog.conf && \
    sed -i 's/\(^\$OmitLocalLogging \).*/\1off/' /etc/rsyslog.conf && \
    rm /etc/rsyslog.d/listen.conf
#To be able to use a host-mounted volume for OTRS configuration we need to move
#away the contents of ${OTRS_CONFIG_DIR} to another place and move them back
#on first container run (see check_host_mount_dir on functions.sh), after the
#host-volume is mounted. The same for the skins.
RUN mv ${OTRS_CONFIG_DIR} / && \
    mv ${SKINS_PATH} / && \
    touch ${OTRS_ROOT}var/tmp/firsttime
EXPOSE 80
CMD ["/run.sh"]
