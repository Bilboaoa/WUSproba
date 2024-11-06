#!/bin/sh

DB_SCRIPTS_URI="https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql"

# Get packages
sudo apt update -y
sudo apt install -y mysql-server wget

# Configure mysql server
sudo sed 's/\(^bind-address\s*=\).*$/\1 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf -i

# Initialize database
sudo mysql -e "CREATE USER 'pc'@'%' IDENTIFIED BY 'petclinic'; GRANT ALL PRIVILEGES ON *.* TO 'pc'@'%' WITH GRANT OPTION;"
wget "$DB_SCRIPTS_URI/initDB.sql" -O - | sudo mysql -f
wget "$DB_SCRIPTS_URI/populateDB.sql" -O - | sudo mysql petclinic -f

# Restart mysql server
sudo service mysql restart
