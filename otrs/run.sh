#!/bin/bash
#service mysqld start &
#wait
#mysql -uroot -e "CREATE DATABASE otrs;CREATE USER 'otrs'@'localhost' IDENTIFIED BY 'otrs';GRANT ALL PRIVILEGES ON otrs.* TO 'otrs'@'localhost' WITH GRANT OPTION;"&
#wait
#mysql -f -u root otrs < /opt/otrs/scripts/database/otrs-schema.mysql.sql &
#wait
#mysql -f -u root otrs < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql &
#wait
#/opt/otrs/bin/otrs.SetPassword.pl --agent root@localhost root &
#wait
#/opt/otrs/bin/otrs.RebuildConfig.pl &
#wait
#/opt/otrs/bin/Cron.sh start otrs &
#wait
#curl -o /tmp/Znuny4OTRS-Repo.opm http://portal.znuny.com/api/addon_repos/public/1420
#/opt/otrs/bin/otrs.PackageManager.pl -a install -p /tmp/Znuny4OTRS-Repo.opm &
#wait
#service httpd start
#wait
#service crond start
#exec /usr/sbin/sshd -D
