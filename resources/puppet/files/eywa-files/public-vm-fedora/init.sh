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
##HOSTNAME="EYWA-VM-`echo $ETH0_IP | sed 's/\./-/g'`"
HOSTNAME="VM-`echo $ETH0_IP | sed 's/\./-/g'`"
##echo "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME.test.org
#echo "$ETH0_IP $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
#echo "127.0.0.1 $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
if [ `grep -c "^HOSTNAME" /etc/sysconfig/network` -eq 0 ]; then
	echo "HOSTNAME=$HOSTNAME.test.org" >> /etc/sysconfig/network
else
	sed -i "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME.test.org/g" /etc/sysconfig/network
fi

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

## iptables OFF
#service iptables stop
systemctl stop firewalld.service
systemctl disable firewalld.service

#/etc/init.d/network restart
systemctl restart network.service

umount -l /mnt
