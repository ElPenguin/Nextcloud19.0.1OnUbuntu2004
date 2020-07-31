#!/bin/bash

cd /etc/php/7.4/fpm/pool.d/
sudo sed -i 's/;env/env/g' www.conf
