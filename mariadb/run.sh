#!/bin/bash
env

#Do normal startup
echo -e "Starting database..."
/docker-entrypoint.sh mysqld_safe & #2>&1>/dev/null&


#If it's the first time the container is run, load up the DB data
while true; do
  out="`/usr/bin/mysql -uroot -e "SELECT COUNT(*) FROM mysql.user;" 2>&1`"
  echo -e "$out"
  echo "$out" | grep "denied"
  if [ $? -eq 0 ]; then
    echo -e "\n\e[92mServer is up !\e[0m\n"
    break
  fi
  echo -e "\n\e[92mMariaDB\e[0m server still isn't up, sleeping a little bit ...\n"
  sleep 2
done
#  rm /var/lib/mysql/ib_logfile*
if [ -e "/var/lib/mysql/firsttime" ]; then
  echo "First time DB inicialization..."
  /usr/bin/mysqladmin -u root -pmysqlPassword password $MYSQL_ROOT_PASSWORD
  echo "root password set."
  echo "Setting root user permissions..."
  /usr/bin/mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
  rm -fr /var/lib/mysql/firsttime
  echo "Finished."
  echo "Cleaning up!"
fi

while true; do
  sleep 1000
done  
