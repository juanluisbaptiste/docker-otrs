# --
# Kernel/Config.pm - Config file for OTRS kernel
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
#  Note:
#
#  -->> Most OTRS configuration should be done via the OTRS web interface
#       and the SysConfig. Only for some configuration, such as database
#       credentials and customer data source changes, you should edit this
#       file. For changes do customer data sources you can copy the definitions
#       from Kernel/Config/Defaults.pm and paste them in this file.
#       Config.pm will not be overwritten when updating OTRS.
# --

package Kernel::Config;

use strict;
use warnings;
use utf8;

sub Load {
    my $Self = shift;

    # ---------------------------------------------------- #
    # database settings                                    #
    # ---------------------------------------------------- #

    # The database host
    $Self->{'DatabaseHost'} = 'mariadb';

    # The database name
    $Self->{'Database'} = "otrs";

    # The database user
    $Self->{'DatabaseUser'} = "otrs";

    # The password of database user. You also can use bin/otrs.CryptPassword.pl
    # for crypted passwords
    $Self->{'DatabasePw'} = 'changeme';

    # The database DSN for MySQL ==> more: "perldoc DBD::mysql"
    $Self->{'DatabaseDSN'} = "DBI:mysql:database=$Self->{Database};host=$Self->{DatabaseHost}";

    # The database DSN for PostgreSQL ==> more: "perldoc DBD::Pg"
    # if you want to use a local socket connection
#    $Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};";
    # if you want to use a TCP/IP connection
#    $Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};host=$Self->{DatabaseHost};";

    # The database DSN for Microsoft SQL Server - only supported if OTRS is
    # installed on Windows as well
#    $Self->{DatabaseDSN} = "DBI:ODBC:driver={SQL Server};Database=$Self->{Database};Server=$Self->{DatabaseHost},1433";

    # The database DSN for Oracle ==> more: "perldoc DBD::oracle"
#    $Self->{DatabaseDSN} = "DBI:Oracle://$Self->{DatabaseHost}:1521/$Self->{Database}";
#
#    $ENV{ORACLE_HOME}     = '/path/to/your/oracle';
#    $ENV{NLS_DATE_FORMAT} = 'YYYY-MM-DD HH24:MI:SS';
#    $ENV{NLS_LANG}        = 'AMERICAN_AMERICA.AL32UTF8';

    # ---------------------------------------------------- #
    # fs root directory
    # ---------------------------------------------------- #
    $Self->{Home} = '/opt/otrs';

    # ---------------------------------------------------- #
    # insert your own config settings "here"               #
    # config settings taken from Kernel/Config/Defaults.pm #
    # ---------------------------------------------------- #
    # $Self->{SessionUseCookie} = 0;
    # $Self->{CheckMXRecord} = 0;

    # ---------------------------------------------------- #

    # ---------------------------------------------------- #
    # data inserted by installer                           #
    # ---------------------------------------------------- #
    # $DIBI$

    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
    #                                                      #
    # end of your own config options!!!                    #
    #                                                      #
    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
    
    $Self->{'LogModule'} = 'Kernel::System::Log::SysLog';
    $Self->{'LogModule::LogFile'} = '/tmp/otrs.log';
    $Self->{'DefaultLanguage'} = 'en';
    $Self->{'CheckMXRecord'} = '1';
    $Self->{'SecureMode'} = 1;

}

# ---------------------------------------------------- #
# needed system stuff (don't edit this)                #
# ---------------------------------------------------- #

use base qw(Kernel::Config::Defaults);

# -----------------------------------------------------#

1;
