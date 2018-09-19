#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install nginx
yum install update
yum -y install httpd
chkconfig httpd on
# make sure nginx is started
service httpd start
