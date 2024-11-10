#!/bin/bash

DB_ADDRESS="$1"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install openjdk-17-jdk -y

cd /home/azuser
mkdir app
cd app

git clone https://github.com/spring-petclinic/spring-petclinic-rest.git
cd spring-petclinic-rest

sed -i "s/localhost/$DB_ADDRESS:3306/" src/main/resources/application-mysql.properties
sed -i "s/hsqldb/mysql/" src/main/resources/application.properties

sudo ./mvnw spring-boot:run -D spring.profiles.active=mysql -Dspring-boot.run.arguments="--spring.profiles.active=mysql,spring-data-jpa --database=mysql"
