#!/bin/sh

# This is a script for making a beaglebone SD card

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

read -p "This will obliterate the partition table on $1... Are you sure? (y/n)" -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then 

umount $1"1"
umount $1"2"

# Create the partition table using fdisk    
echo "
o
n
p
1

+100M
t
c
n
p
2


w
" | fdisk $1
partprobe
fdisk -l $1

mkfs.vfat -v $1"1"
mkfs.ext4 -v $1"2"

rm -rf /tmp/boot /tmp/root

# Get and install the root filesystem
wget http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz -O /tmp/rootfs.tar.gz

mkdir /tmp/root /tmp/boot
mount $1"1" /tmp/boot
mount $1"2" /tmp/root

bsdtar -xvf /tmp/rootfs.tar.gz -C /tmp/root
sync

mv -v /tmp/root/boot/* /tmp/boot

umount /tmp/boot
umount /tmp/root
rm -rf /tmp/boot /tmp/root

fi
