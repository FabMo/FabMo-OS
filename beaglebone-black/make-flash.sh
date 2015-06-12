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

# Zero out the beginning of the disk
dd if=/dev/zero of=$1 bs=1M count=8

# Create the partition table using fdisk    
echo "
o
n
p
1
2048
+1.5G
n
p
2

+1G
n
p
3

+1G
w

" |
 fdisk $1
partprobe
fdisk -l $1

mkfs.ext4 -v $1"p1"
mkfs.btrfs -f -m raid1 -d raid1 $1"p2" $1"p3"


# Get an install the root filesystem
wget http://archlinuxarm.org/os/ArchLinuxARM-am33x-latest.tar.gz -O /tmp/rootfs.tar.gz
rm -rf /tmp/root
mkdir -p /tmp/root
mount $1"p1" /tmp/root
bsdtar -xf /tmp/rootfs.tar.gz -C /tmp/root

# Install the u-boot bootloader
dd if=/tmp/root/boot/MLO of=$1 count=1 seek=1 conv=notrunc bs=128k
dd if=/tmp/root/boot/u-boot.img of=$1 count=2 seek=1 conv=notrunc bs=384k
 
# Install the bootstrap script that will build the system from the chrooted environment
cp ./bootstrap.sh /tmp/root/root
arch-chroot /tmp/root /bin/bash -c /root/bootstrap.sh
umount /tmp/root
sync

fi
