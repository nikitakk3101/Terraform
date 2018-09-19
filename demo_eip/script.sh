#!/bin/bash
# install httpd
sudo yum install update
sudo yum -y install httpd
sudo chkconfig httpd on
# make sure httpd is started
sudo service httpd start
