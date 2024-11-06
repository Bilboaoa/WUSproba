#!/bin/bash


API_URL="$1"
FE_URL="$2"

sudo apt update -y
sudo apt install nginx -y

cd /home/azuser

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


nvm install 12.11.1

git clone https://github.com/spring-petclinic/spring-petclinic-angular.git

cd spring-petclinic-angular/
sed -i "s/localhost/$FE_URL/g" src/environments/environment.ts src/environments/environment.prod.ts
sed -i "s/9966/4200/g" src/environments/environment.ts src/environments/environment.prod.ts

echo Log: | npm install -g @angular/cli@11.2.11
echo Log: | npm install
echo Log: | ng analytics off

ng build --prod --base-href=/petclinic/ --deploy-url=/petclinic/

sudo mkdir /usr/share/nginx/html/petclinic
sudo cp -r dist/ /usr/share/nginx/html/petclinic

cat > petclinic.conf << EOL
server {
	listen       4200 default_server;
    root         /usr/share/nginx/html;
    index /petclinic/index.html;

	location /petclinic/ {
        alias /usr/share/nginx/html/petclinic/dist/;
        try_files \$uri\$args \$uri\$args/ /petclinic/index.html;
    }

    location /petclinic/api/ {
        proxy_pass http://${API_URL}:9966;
        include proxy_params;
    }
}
EOL

sudo mv petclinic.conf /etc/nginx/conf.d/petclinic.conf

sudo rm /etc/nginx/sites-enabled/default

sudo nginx -s reload
