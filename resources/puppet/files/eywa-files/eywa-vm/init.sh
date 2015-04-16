#!/bin/bash

## root 계정 비번 제거
sed -i '/root/d' /etc/shadow
echo "root:!:16038:0:99999:7:::" >> /etc/shadow

echo "
acpiphp
pci_hotplug" >> /etc/modules
for m in acpiphp pci_hotplug; do sudo modprobe ${m}; done

if [ ! -z $PASSWD ]; then
	echo "root:$PASSWD" | chpasswd
	#echo "password" | passwd --stdin root
fi

cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime

## HOSTNAME 설정
#HOSTNAME="EYWA-VM-${ONE_UID}-`echo $ETH0_IP | sed 's/\./-/g'`"
HOSTNAME="VM-${ONE_UID}-`echo $ETH0_IP | sed 's/\./-/g'`"
echo "$HOSTNAME.test.org" > /etc/hostname
#echo "$ETH0_IP $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
#echo "127.0.0.1 $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
/etc/init.d/hostname restart

echo "nameserver 192.168.33.11
nameserver 168.126.63.1" > /etc/resolv.conf

HOME="/root"
#mkdir -p $HOME/.ssh
rm -rf $HOME/.ssh 2> /dev/null
cp -a /mnt/.ssh $HOME/
chmod 644 $HOME/.ssh/*
chmod 600 $HOME/.ssh/id_rsa
echo $SSH_PUBLIC_KEY >> $HOME/.ssh/authorized_keys
chown -R root:root $HOME

#echo "### Internal apt-get Mirror
#deb http://192.168.33.11/ubuntu precise main restricted universe
#deb http://192.168.33.11/ubuntu precise-updates main restricted universe
#deb http://192.168.33.11/ubuntu precise-security main restricted universe multiverse" > /etc/apt/sources.list

/etc/init.d/networking restart

umount -l /mnt

update-rc.d vmcontext disable
echo -e "nameserver 192.168.33.11\nnameserver 168.126.63.1" >> /etc/resolvconf/resolv.conf.d/head

## for Test Apache
apt-get	update
apt-get install apache2
sleep 1
echo "<html><body><h1>It works. ($(ifconfig eth0 | awk '/inet addr/ {print $2}' | cut -d: -f2))</h1>" > /var/www/index.html
