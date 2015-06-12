#!/bin/sh

# Update the system
echo "Updating ArchLinux"
pacman --noconfirm -Syu
pacman --noconfirm -S base-devel git

# Switch kernels - The am33x kernel is newer (overlayfs support) but no video
echo "Switching to linux-am33x kernel"
pacman --noconfirm -S linux-am33x

# Install liveroot by bluerider (enables a root overlay)
echo "Installing root overlay"
git clone https://github.com/bluerider/liveroot /tmp/liveroot
cp /tmp/liveroot/initcpio/hooks/* /usr/lib/initcpio/hooks
cp /tmp/liveroot/initcpio/install/* /usr/lib/initcpio/install

# Configure and install an initial ramdisk environment
# with root overlay enabled.
echo 'MODULES="overlay btrfs"
FILES=""
BINARIES=""
HOOKS="base udev oroot autodetect modconf block filesystems keyboard fsck"
COMPRESSION="gzip"
COMPRESSION_OPTIONS=""' > /tmp/mkinitcpio.conf
KERNEL=`ls /usr/lib/modules | grep "4*ARCH"`
echo "Building initramfs for $KERNEL kernel"
mkinitcpio -c /tmp/mkinitcpio.conf -g /boot/initramfs-linux.img -k $KERNEL

# Configure bootloader settings to enable root overlay with kernel params
echo "Enabling root overlay in bootloader"
echo 'optargs=coherent_pool=1M oroot=raw' > /boot/uEnv.txt

# Create and configure mount point for writable partition
mkdir -p /opt/fabmo
echo '/dev/mmcblk0p3 /opt/fabmo	btrfs' > /etc/fstab

# Install dependencies for fabmo
echo "Installing fabmo dependencies"
pacman --noconfirm -S python2 nodejs npm

# Install fabmo
echo "Installing fabmo"
rm -rf /fabmo /opt/fabmo
mkdir /fabmo
mkdir -p /opt/fabmo
git clone https://github.com/FabMo/FabMo-Engine.git /fabmo
cd /fabmo
npm install

# Configure fabmo as a service
echo "Enabling fabmo as a service"
echo '[Unit]
Description=FabMo Engine

[Service]
ExecStart=/bin/node /fabmo/server.js &
Type=simple
User=root
Restart=always
StandardOutput=syslog
StandardError=syslog
WorkingDirectory=/fabmo/

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/fabmo.service

systemctl enable fabmo

