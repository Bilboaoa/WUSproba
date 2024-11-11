#!/bin/sh

DB_SCRIPTS_URI="https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql"
MY_SQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Get packages
sudo apt update -y
sudo apt install -y mysql-server wget

# Configure mysql server
sudo sed 's/\(^bind-address\s*=\).*$/\1 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf -i

sudo bash -c 'cat > in.sql' << EOL
CREATE DATABASE IF NOT EXISTS petclinic;

ALTER DATABASE petclinic
  DEFAULT CHARACTER SET utf8
  DEFAULT COLLATE utf8_general_ci;

CREATE USER IF NOT EXISTS 'petclinic'@'%' IDENTIFIED BY 'petclinic';
CREATE USER IF NOT EXISTS 'replicate'@'%' IDENTIFIED BY 'slave_pass';

GRANT ALL PRIVILEGES ON petclinic.* TO 'petclinic'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'replicate'@'%';
ALTER USER 'replicate'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'slave_pass';


FLUSH PRIVILEGES;
EOL

echo "server-id = 1" >>MY_SQL_CONFIG
echo "log-bin = mysql-bin" >>MY_SQL_CONFIG

echo "general_log = 1" >>MY_SQL_CONFIG
echo "general_log_file = /var/log/mysql/mysql.log" >>MY_SQL_CONFIG

# Initialize database
sudo mysql < in.sql
wget "$DB_SCRIPTS_URI/schema.sql" -O schema.sql
sudo mysql petclinic < schema.sql
wget "$DB_SCRIPTS_URI/data.sql" -O data.sql
sudo mysql petclinic < data.sql

# Restart mysql server
sudo service mysql restart
