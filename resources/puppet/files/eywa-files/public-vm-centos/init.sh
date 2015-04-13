#!/bin/bash

sed -i 's/SELINUX=.*/SELINUX=permissive/g' /etc/sysconfig/selinux 
setenforce 0

## root 계정 비번 제거
sed -i '/root/d' /etc/shadow
echo "root:!:16105:0:99999:7:::" >> /etc/shadow

cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime

#echo "
#acpiphp
#pci_hotplug" >> /etc/modules
#for m in acpiphp pci_hotplug; do sudo modprobe ${m}; done

if [ ! -z $PASSWD ]; then
	#echo "root:$PASSWD" | chpasswd
	echo "$PASSWD" | passwd --stdin root
fi

## HOSTNAME 설정
#HOSTNAME="EYWA-VM-`echo $ETH0_IP | sed 's/\./-/g'`"
HOSTNAME="VM-`echo $ETH0_IP | sed 's/\./-/g'`"
#echo "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME.test.org
#echo "$ETH0_IP $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
echo "127.0.0.1 $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts

echo "nameserver 192.168.33.11
nameserver 168.126.63.1" > /etc/resolv.conf

## iptables OFF
service iptables stop

/etc/init.d/network restart

umount -l /mnt

