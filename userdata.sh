#!/bin/bash
sleep 1m
sudo su - root
yum install -y amazon-efs-utils
file_system_id="${efs_id}"
mkdir -p /mnt/efs
mount  -t efs $file_system_id:/ /mnt/efs
chown ec2-user:ec2-user /mnt/efs
# Edit fstab so EFS automatically loads on reboot
echo "$file_system_id:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab






