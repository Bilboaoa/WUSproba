#!/bin/bash


API_URL="$1"
FE_URL="$2"
BE_PORT="$3"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt autoremove -y
sudo apt-get install curl -y
sudo apt-get install npm -y
sudo apt update -y
sudo apt install nginx -y

cd /home/azuser

git clone https://github.com/spring-petclinic/spring-petclinic-angular.git

cd spring-petclinic-angular/
sed -i "s/localhost/$FE_URL/g" src/environments/environment.ts src/environments/environment.prod.ts
sed -i "s/9966/$BE_PORT/g" src/environments/environment.ts src/environments/environment.prod.ts

sudo apt-get remove --purge nodejs

sudo -s

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# source ~/.bashrc
nvm install 18.19
nvm use 18.19

echo Log: | npm install -g @angular/cli@latest
echo Log: | npm install
echo Log: | ng analytics off


# ng build --prod --base-href=/petclinic/ --deploy-url=/petclinic/
ng build --configuration production --base-href=/petclinic/ --deploy-url=/petclinic/

# sudo npm install @angular/cli@11.2.11 --save-dev #install locally 
# sudo npx ng build --prod --base-href=/petclinic/ --deploy-url=/petclinic/ # build locally


mkdir /usr/share/nginx/html/petclinic

cp -r dist/ /usr/share/nginx/html/petclinic

sudo bash -c 'cat > /etc/nginx/conf.d/petclinic.conf' << EOL
server {
    listen 8080 default_server;
    root /usr/share/nginx/html/petclinic/dist;
    index index.html;

    location /petclinic/ {
        alias /usr/share/nginx/html/petclinic/dist/;
        try_files \$uri \$uri/ /petclinic/index.html;
    }

    # API proxy to backend server
    location /petclinic/api/ {
        proxy_pass http://${API_URL}:9966;
        include proxy_params;
    }
}

EOL

sudo rm /etc/nginx/sites-enabled/default

sudo systemctl restart nginx
