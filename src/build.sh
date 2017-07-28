#!/bin/bash

# Set bash to strict mode
set -euvo pipefail

# Install server services
sudo apt-get -yq udpate
sudo apt-get -yq upgrade
# TODO: determine if nfs-kernel-server and syslinux-common are needed
sudo apt-get -yq install curl dnsmasq nfs-kernel-server nginx squid3 syslinux-common

# Move over service configurations
sudo mv ./etc/nginx/nginx.conf /etc/nginx/nginx.conf
sudo mv ./etc/dnsmasq.conf /etc/dnsmasq.conf
sudo mv ./etc/iptables.conf /etc/iptables.conf
sudo mv ./etc/squid3/squid.conf.template /etc/squid3/squid.conf.template

# Build server directories for HTTP and TFTP/DHCP
sudo mkdir -p /srv/http
sudo mkdir -p /srv/tftp/grub
sudo mv ./srv/http/* /srv/http
sudo mv ./srv/tftp/grub/* /srv/tftp/grub

# Fetch Ubuntu image and llayout the tftp directory (roughly)
curl -Ls http://archive.ubuntu.com/ubuntu/dists/zesty/main/installer-amd64/current/images/netboot/netboot.tar.gz | sudo tar xvf - -C /srv/tftp/
sudo curl -L http://archive.ubuntu.com/ubuntu/dists/zesty/main/uefi/grub2-amd64/current/grubnetx64.efi.signed -o /srv/tftp/grubnetx64.efi.signed

# Graft our preseed file onto the initrd.gz initial ramdisk, because grub doesn't seem to like injecting it over http
sudo mkdir -p /srv/tftp/ubuntu-installer/amd64/irmod
sudo gzip -d < /srv/tftp/ubuntu-installer/amd64/initrd.gz | sudo cpio --extract --verbose --make-directories --no-absolute-filenames
sudo cp ./srv/http/preseed.cfg /srv/tftp/ubuntu-installer/amd64/irmod/preseed.cfg
sudo find . | sudo cpio -H newc --create --verbose | sudo gzip -9 | sudo tee /srv/tftp/ubuntu-installer/amd64/initrd.gz > /dev/null
sudo rm -rf /srv/tftp/ubuntu-installer/amd64/irmod

# Set IPv4 ip forward for the kernel
sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

# Reboot it
sudo reboot
