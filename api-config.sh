#!/bin/bash

DB_ADDRESS="$1"


sudo apt update -y
sudo apt install -y openjdk-11-jdk

cd /home/azuser
mkdir app
cd app

git clone https://github.com/spring-petclinic/spring-petclinic-rest.git
cd spring-petclinic-rest

sed -i "s/localhost:3306/$DB_ADDRESS:3306/" src/main/resources/application-mysql.properties
sed -i "s/hsqldb/mysql/" src/main/resources/application.properties

sudo ./mvnw spring-boot:run &
