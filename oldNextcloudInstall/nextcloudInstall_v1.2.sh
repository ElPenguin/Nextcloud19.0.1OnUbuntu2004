#!/bin/bash

# Important Var
MYSQL_ROOT_PASSWORD=""

# Add lastest PHP ver
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > ondrej-ubuntu-php-focal.list
echo "# deb-src http://ppa.launchpad.net/ondrej/php/ubuntu focal main" >> ondrej-ubuntu-php-focal.list
sudo mv ondrej-ubuntu-php-focal.list /etc/apt/sources.list.d/ondrej-ubuntu-php-focal.list

# Add lastest MariaDB ver
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'

# Update and Upgrade with the new repo
sudo apt -y update && sudo apt -y upgrade

# Install essential app for the futur system
sudo apt -y install nginx unzip zip openssl gcc make autoconf libc-dev pkg-config memcached software-properties-common p7zip mariadb-server mariadb-client expect

# Launch Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Set the write and Read rules for Nginx
sudo chown www-data:www-data /usr/share/nginx/html -R

# Launch MariaDB
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Mysql Secure Installation Automate. If you want to change the root password, change "MYSQL_ROOT_PASSWORD=""" by "MYSQL_ROOT_PASSWORD="YOUR_PASSWORD""
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Switch to unix_socket authentication\"
send \"n\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"

# Install the lastest PHP ver
sudo apt -y install php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl php-imagick php7.4-zip php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp php-pear php-dev php-imagick php7.4-memcached

# Launch PHP
sudo systemctl enable php7.4-fpm
sudo systemctl start php7.4-fpm

# Get Nextcloud ver 19.0.0, unzip and send in the right folder
wget https://download.nextcloud.com/server/releases/nextcloud-19.0.0.zip
sudo unzip nextcloud-19.0.0.zip -d /usr/share/nginx/
sudo chown www-data:www-data /usr/share/nginx/nextcloud/ -R

# Create the Nextcloud user in DB
sudo mariadb -u root -e "create database nextclouddb;"
sudo mariadb -u root -e "create user nextcloud@localhost identified by 'ergz5uirg4664!e';"
sudo mariadb -u root -e "grant all privileges on nextclouddb.* to nextcloud@localhost identified by 'ergz5uirg4664!e';"
sudo mariadb -u root -e "flush privileges;"

# Add SSL encryption
sudo mkdir /etc/ssl/nginx/
commonname=$(hostname -I)

# Change this following details by your own
country=FR
state=Bourgogne
locality=Dijon
organization=Uncorp
organizationalunit=Uncorp
email=example@email.com

sudo openssl req -x509 -nodes -days 5365 -newkey rsa:2048 -keyout /etc/ssl/nginx/nextcloud.key -out /etc/ssl/nginx/nextcloud.crt \
	-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

# Suppr Nginx default conf and add the right conf
sudo rm /etc/nginx/sites-enabled/default
cat > nextcloud.conf <<-EOF
upstream php-handler {
    server 127.0.0.1:9000;
    server unix:/var/run/php/php7.4-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name $commonname;
EOF
echo "    return 301 https://""$""server_name:443""$""request_uri;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $commonname;

    ssl_certificate /etc/ssl/nginx/nextcloud.crt;
    ssl_certificate_key /etc/ssl/nginx/nextcloud.key;

    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "none" always;
    add_header X-XSS-Protection "1; mode=block" always;

    fastcgi_hide_header X-Powered-By;

    root /usr/share/nginx/nextcloud;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location = /.well-known/carddav {
EOF
echo "      return 301 ""$""scheme://""$""host:""$""server_port/remote.php/dav;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
    }
    location = /.well-known/caldav {
EOF
echo "      return 301 ""$""scheme://""$""host:""$""server_port/remote.php/dav;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
    }

    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    location / {
        rewrite ^ /index.php;
    }

    location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

EOF
echo "    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:""$""|\/) {" >> nextcloud.conf
echo "        fastcgi_split_path_info ^(.+?\.php)(\/.*|)""$"";" >> nextcloud.conf
echo "        set ""$""path_info ""$""fastcgi_path_info;" >> nextcloud.conf
echo "        try_files ""$""fastcgi_script_name =404;" >> nextcloud.conf
echo "        include fastcgi_params;" >> nextcloud.conf
echo "        fastcgi_param SCRIPT_FILENAME ""$""document_root""$""fastcgi_script_name;" >> nextcloud.conf
echo "        fastcgi_param PATH_INFO ""$""path_info;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

EOF
echo "    location ~ ^\/(?:updater|oc[ms]-provider)(?:""$""|\/) {" >> nextcloud.conf
echo "        try_files ""$""uri/ =404;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
        index index.php;
    }

EOF
echo "    location ~ \.(?:css|js|woff2?|svg|gif|map)""$"" {" >> nextcloud.conf
echo "        try_files ""$""uri /index.php""$""request_uri;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
        add_header Cache-Control "public, max-age=15778463";
        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        access_log off;
    }

EOF
echo "    location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)""$"" {" >> nextcloud.conf
echo "        try_files ""$""uri /index.php""$""request_uri;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
        access_log off;
    }
}
EOF
sudo mv nextcloud.conf /etc/nginx/conf.d/nextcloud.conf
sudo systemctl restart nginx

# Set Cache
sudo pecl install geoip-beta
sudo printf "\n" | sudo pecl install apcu
sudo bash -c "echo extension=apcu.so > /etc/php/7.4/fpm/conf.d/apcu.ini"
sudo service php7.4-fpm restart
