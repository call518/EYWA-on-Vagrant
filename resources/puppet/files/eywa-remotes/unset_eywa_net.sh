#!/bin/bash

DB_HOST="192.168.33.10"
DB_NAME="eywa"
DB_USER="eywa"
DB_PASS="1234"
MYSQL_EYWA="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST $DB_NAME -s -N"
T64=$1
XPATH="/var/tmp/one/hooks/eywa/xpath.rb -b $T64"
SSH_oneadmin="ssh oneadmin@192.168.33.10 -i /var/lib/one/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5"

ONE_VM_ID=`$XPATH /VM/ID`
ONE_UID=`$XPATH /VM/TEMPLATE/CONTEXT/ONE_UID`
ONE_GID=`$XPATH /VM/GID`
ONE_HID=`$XPATH /VM/HISTORY_RECORDS/HISTORY/HID`
ONE_ETH0_IP=`$XPATH /VM/TEMPLATE/NIC/IP`
ONE_IS_EYWA=`$XPATH /VM/TEMPLATE/CONTEXT/IS_EYWA`
ONE_IS_VR=`$XPATH /VM/TEMPLATE/CONTEXT/IS_VR`
ONE_PASSWD=`$XPATH /VM/TEMPLATE/CONTEXT/PASSWD`
ONE_SSH_PUBLIC_KEY=`$XPATH /VM/TEMPLATE/CONTEXT/SSH_PUBLIC_KEY`
VR_PRI_IP="10.0.0.1"

QUERY_MC_ADDRESS=($($MYSQL_EYWA -e "select num,address from mc_address where uid='$ONE_UID'"))
VXLAN_G_N=${QUERY_MC_ADDRESS[0]} # VXLAN Group Number
VXLAN_G_A=${QUERY_MC_ADDRESS[1]} # VXLAN Group Address

EXIST_EYWA_VRs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='1' and uid='$ONE_UID' and vid!='$ONE_VM_ID' and hid='$ONE_HID' and deleted='0'"`
EXIST_EYWA_VMs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='0' and uid='$ONE_UID' and vid!='$ONE_VM_ID' and hid='$ONE_HID' and deleted='0'"`

#--------------------------------------------------------------------------------------------

function undeploy_network() {
	sudo ifconfig VSi$VXLAN_G_N down
	sudo brctl delif VSi$VXLAN_G_N vxlan$VXLAN_G_N
	sudo ip link delete vxlan$VXLAN_G_N
	sudo brctl delbr VSi$VXLAN_G_N
}

#--------------------------------------------------------------------------------------------

#if [ "$ONE_IS_EYWA" == "yes" ]; then
#	if [ "$ONE_IS_VR" == "yes" ]; then
#		if [ $EXIST_EYWA_VRs -eq 0 ] && [ $EXIST_EYWA_VMs -eq 0 ]; then
#			undeploy_network
#			sudo arptables -D FORWARD -j DROP -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1
#		fi
#		sudo arptables -D FORWARD -j DROP -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2
#		sudo arptables -D FORWARD -j DROP -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1
#	else
#		if [ $EXIST_EYWA_VRs -eq 0 ]; then
#			if [ $EXIST_EYWA_VMs -eq 0 ]; then
#				undeploy_network
#				#sudo arptables -D FORWARD -j DROP -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1
#			fi
#			sudo arptables -D FORWARD -j DROP -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2
#			sudo arptables -D FORWARD -j DROP -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1
#		else
#			## 대상 HOST에 동일 계정의 VR이 존재할 경우, 
#			if [ $EXIST_EYWA_VMs -eq 0 ]; then
#				## 대상 HOST에 동일 계정의 VM이 존재치 않을 경우,
#				## (VM이 전혀 없이 VR혼자만 노드에 있는 특수한 경우... 일단 무작업으로 Case는 유지..)
#				echo "Pass...."
#			else
#				## 대상 HOST에 동일 계정의 VM이 존재할 경우,
#				## (역시, 기존의 arptables 정책이나, BR설정을 변경할 요소가 없음. VM만 단순 삭제 처리...)
#				echo "Pass...."
#			fi
#		fi
#	fi
#fi

#--------------------------------------------------------------------------------------------

## Delete ARP Policy
if [ "$ONE_IS_VR" == "yes" ] && [ $EXIST_EYWA_VRs -eq 0 ]; then
	sudo arptables -D FORWARD -j DROP -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1
	sudo arptables -D FORWARD -j DROP -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1
fi

## Undeploy aprtables and network...
if [ $EXIST_EYWA_VRs -eq 0 ] && [ $EXIST_EYWA_VMs -eq 0 ]; then
	undeploy_network
fi

$MYSQL_EYWA -e "update vm_info set deleted='1' where vid='$ONE_VM_ID'"
