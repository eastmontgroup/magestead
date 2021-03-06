#!/usr/bin/env bash

APP_NAME=${1};
DIR=${2};
BASE_URL=${3};

block="server {
    listen 80;
    server_name $BASE_URL;
    set \$MAGE_ROOT $DIR/public;
    set \$MAGE_MODE developer;

    root \$MAGE_ROOT/pub;

    index index.php;
    autoindex off;
    charset off;

    access_log /var/log/nginx/$BASE_URL-access.log;
    error_log /var/log/nginx/$BASE_URL-error.log error;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location /pub {
        alias \$MAGE_ROOT/pub;
    }

    location /static/ {
        if (\$MAGE_MODE = \"production\") {
            expires max;
        }
        location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)$ {
            add_header Cache-Control \"public\";
            expires +1y;

            if (!-f \$request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=\$2 last;
            }
        }
        location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
            add_header Cache-Control \"no-store\";
            expires    off;

            if (!-f \$request_filename) {
               rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=\$2 last;
            }
        }
        if (!-f \$request_filename) {
            rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=\$2 last;
        }
    }

    location /media/ {
        try_files \$uri \$uri/ /get.php?\$args;
        location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)$ {
            add_header Cache-Control \"public\";
            expires +1y;
            try_files \$uri \$uri/ /get.php?\$args;
        }
        location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
            add_header Cache-Control \"no-store\";
            expires    off;
            try_files \$uri \$uri/ /get.php?\$args;
        }
    }

    location /media/customer/ {
        deny all;
    }

    location /media/downloadable/ {
        deny all;
    }

    location ~ /media/theme_customization/.*\.xml$ {
        deny all;
    }

    location /errors/ {
        try_files \$uri =404;
    }

    location ~ ^/errors/.*\.(xml|phtml)$ {
        deny all;
    }

    location ~ cron\.php {
        deny all;
    }

    location ~ (index|get|static|report|404|503)\.php$ {
        try_files \$uri =404;
        fastcgi_pass   127.0.0.1:9090;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index  index.php;

        fastcgi_param  PHP_FLAG  \"session.auto_start=off \n suhosin.session.cryptua=off\";
        fastcgi_param  PHP_VALUE \"memory_limit=256M \n max_execution_time=600\";
        fastcgi_read_timeout 600s;
        fastcgi_connect_timeout 600s;
        fastcgi_param  MAGE_MODE \$MAGE_MODE;

        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
"

sudo echo "$block" > "/etc/nginx/sites-available/$APP_NAME.conf"
cd /etc/nginx/sites-enabled;
sudo ln -s "/etc/nginx/sites-available/$APP_NAME.conf"
sudo service nginx restart