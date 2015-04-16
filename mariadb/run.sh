#!/bin/bash
FIRST_TIME="/tmp/firsttime"

#Do normal startup
/start.sh 2>&1>/dev/null&

#If it's the first time the container is run, load up the DB data
if [ -f "$FIRST_TIME" ];then
  rm /var/lib/mysql/ib_logfile*
	while true; do
		out="`/usr/bin/mysql -uroot -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
		echo -e "$out"
		echo "$out" | grep "denied"
		if [ $? -eq 0 ]; then
			echo -e "\n\e[92mServer is up !\e[0m\n"
			break
		fi
		echo -e "\nMariaDB server still isn't up, sleeping a little bit ...\n"
		sleep 2
	done
	  rm /var/lib/mysql/ib_logfile*
    echo "First time DB inicialization, loading data..."
    /usr/bin/mysqladmin -u root -pmysqlPassword password $MYSQL_ROOT_PASSWORD
    echo "root password set."
    echo "Setting root user permissions..."
    /usr/bin/mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
    echo "Loading website data..."

    for i in `ls /tmp/sql/*.sql`; do
        echo -e "Loading \e[92m$i\e[0m"
        /usr/bin/mysql -u root -p$MYSQL_ROOT_PASSWORD < $i
    done
    echo "Finished."
    echo "Cleaning up!"
    rm -fr $FIRST_TIME /tmp/sql/
fi

while true; do
  sleep 1000
done  
