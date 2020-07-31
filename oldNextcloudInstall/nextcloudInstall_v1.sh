#!/bin/bash

sudo apt -y update && sudo apt -y upgrade
sudo apt -y install nginx unzip zip openssl gcc make autoconf libc-dev pkg-config memcached software-properties-common p7zip
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'
sudo apt -y update
sudo apt -y install mariadb-server mariadb-client
sudo systemctl enable nginx
sudo systemctl start nginx
sudo chown www-data:www-data /usr/share/nginx/html -R
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo mysql_secure_installation
sudo apt -y update && sudo apt -y upgrade
sudo apt -y install php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl php-imagick php7.4-zip php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp php-pear php-dev php-imagick php7.4-memcached
sudo systemctl enable php7.4-fpm
sudo systemctl start php7.4-fpm
wget https://download.nextcloud.com/server/releases/nextcloud-19.0.0.zip
sudo unzip nextcloud-19.0.0.zip -d /usr/share/nginx/
sudo chown www-data:www-data /usr/share/nginx/nextcloud/ -R
sudo mariadb -u root
sudo rm /etc/nginx/sites-enabled/default
sudo mkdir /etc/ssl/nginx/
sudo openssl req -x509 -nodes -days 5365 -newkey rsa:2048 -keyout /etc/ssl/nginx/nextcloud.key -out /etc/ssl/nginx/nextcloud.crt
cat > nextcloud.conf <<-EOF
upstream php-handler {
    server 127.0.0.1:9000;
    server unix:/var/run/php/php7.4-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name 10.10.10.10;
EOF
echo "    return 301 https://""$""server_name:443""$""request_uri;" >> nextcloud.conf
cat >> nextcloud.conf <<-EOF
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name 10.10.10.10;

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
sudo pecl install geoip-beta
sudo pecl install apcu
sudo bash -c "echo extension=apcu.so > /etc/php/7.4/fpm/conf.d/apcu.ini"
sudo service php7.4-fpm restart