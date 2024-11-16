#!/bin/bash

BALANCER_PORT=$1
BACKEND_WRITE_ADDRESS=$2
BACKEND_WRITE_PORT=$3
BACKEND_READ_ADDRESS=$4
BACKEND_READ_PORT=$5

sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y nginx

cd ~/

cat > loadbalancerfilter.conf << EOL
server {
  listen      $BALANCER_PORT;
  location /petclinic/api {
    if (\$request_method = POST ) {
      proxy_pass http://$BACKEND_WRITE_ADDRESS:$BACKEND_WRITE_PORT;
    }

    if (\$request_method = PUT) {
      proxy_pass http://$BACKEND_WRITE_ADDRESS:$BACKEND_WRITE_PORT;
    }

    if (\$request_method = DELETE) {
      proxy_pass http://$BACKEND_WRITE_ADDRESS:$BACKEND_WRITE_PORT;
    }
    if (\$request_method = OPTIONS) {
      proxy_pass http://$BACKEND_WRITE_ADDRESS:$BACKEND_WRITE_PORT;
    }

    if (\$request_method = GET ) {
       proxy_pass http://$BACKEND_READ_ADDRESS:$BACKEND_READ_PORT;
    }
  }
}
EOL

sudo mv loadbalancerfilter.conf /etc/nginx/conf.d/loadbalancerfilter.conf

sudo nginx -s reload
