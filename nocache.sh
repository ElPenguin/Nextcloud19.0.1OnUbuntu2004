#!/bin/bash

cd /usr/share/nginx/nextcloud/config/
sudo sed -i 's/);//g' config.php
sudo cat >> config.php <<-EOF
  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.distributed' => '\OC\Memcache\Memcached',
  'memcached_servers' => array(
    array('localhost', 11211),
  ),
);
EOF
