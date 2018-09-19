#!/bin/bash
mkfs -t ext4 /dev/xvdc
mkdir /mount1
mount /dev/xvdc /mount1
echo /dev/xvdc /mount1 ext4 defaults 0 0 >> /etc/fstab