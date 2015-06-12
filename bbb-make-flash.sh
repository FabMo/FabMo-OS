#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

read -p "This will obliterate the partition table on $1... Are you sure? (y/n)" -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then 

pacman --noconfirm -S btrfs-progs

umount $1"p1"
umount $1"p2"
umount $1"p3"
umount $1"p4"

# Create the partition table using fdisk    
echo "
o
n
p
1

+64M
t
e
a
n
p
2

+1.5G
n
p
3

+1G
n
p

+1G
w

" |
 fdisk $1
partprobe
fdisk -l $1

mkfs.vfat -v -F 16 $1"p1"
mkfs.ext4 -v $1"p2"
mkfs.btrfs -m raid1 -d raid1 $1"p3" $1"p4"

rm -rf /tmp/boot /tmp/root

# Get and install the bootloader
wget http://archlinuxarm.org/os/omap/BeagleBone-bootloader.tar.gz -O /tmp/bootloader.tar.gz
mkdir -p /tmp/boot
mount $1"p1" /tmp/boot
tar -xvf /tmp/bootloader.tar.gz -C /tmp/boot
umount /tmp/boot
rm -rf /tmp/boot

# Get an install the root filesystem
wget http://archlinuxarm.org/os/ArchLinuxARM-am33x-latest.tar.gz -O /tmp/rootfs.tar.gz
mkdir /tmp/root
mount $1"p2" /tmp/root
bsdtar -xf /tmp/rootfs.tar.gz -C /tmp/root
cp ./bootstrap.sh /tmp/root/root 
arch-chroot /tmp/root /bin/bash -c /root/root/bootstrap.sh
umount /tmp/root
fi
