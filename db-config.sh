#!/bin/sh

DB_SCRIPTS_URI="https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql"

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

GRANT ALL PRIVILEGES ON petclinic.* TO 'petclinic'@'%';

FLUSH PRIVILEGES;
EOL

# Initialize database
sudo mysql -e "CREATE USER 'pc'@'%' IDENTIFIED BY 'petclinic'; GRANT ALL PRIVILEGES ON *.* TO 'pc'@'%' WITH GRANT OPTION;"
wget "$DB_SCRIPTS_URI/schema.sql" -O - | sudo mysql -f
wget "$DB_SCRIPTS_URI/data.sql" -O - | sudo mysql petclinic -f

# Restart mysql server
sudo service mysql restart
