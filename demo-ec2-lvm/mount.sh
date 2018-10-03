#!/bin/bash
#create physical volumes
pvcreate /dev/xvdb /dev/xvdc
#create lvm group
vgcreate lvmgroup /dev/xvdb /dev/xvdc
#assign disk size to specific logical volume
lvcreate -L 2G -n backup lvmgroup
lvcreate -L 2G -n application lvmgroup
lvcreate -L 2G -n db lvmgroup
lvcreate -l 100%FREE -n  workspace lvmgroup
#format each logical volume
mkfs.ext4 /dev/mapper/lvmgroup-backup
mkfs.ext4 /dev/mapper/lvmgroup-application
mkfs.ext4 /dev/mapper/lvmgroup-db 
mkfs.ext4 /dev/mapper/lvmgroup-workspace
#make directory for logical volume mounting
mkdir -p /mnt/{backup,application,db,workspace}
#mount volumes to specific directory
mount /dev/mapper/lvmgroup-backup /mnt/backup
mount /dev/mapper/lvmgroup-application /mnt/application
mount /dev/mapper/lvmgroup-db /mnt/db
mount /dev/mapper/lvmgroup-workspace /mnt/workspace
#make fstab entry for permanent mounting
echo /dev/mapper/lvmgroup-backup /mnt/backup ext4 defaults,nofail 0 0 >> /etc/fstab
echo /dev/mapper/lvmgroup-application /mnt/application ext4 defaults,nofail 0 0 >> /etc/fstab
echo /dev/mapper/lvmgroup-db /mnt/db ext4 defaults,nofail 0 0 >> /etc/fstab
echo /dev/mapper/lvmgroup-workspace /mnt/workspace ext4 defaults,nofail 0 0 >> /etc/fstab