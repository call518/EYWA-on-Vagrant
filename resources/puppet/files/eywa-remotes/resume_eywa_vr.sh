#!/bin/bash

DB_HOST="172.21.18.11"
DB_NAME="eywa"
DB_USER="eywa"
DB_PASS="1234"
MYSQL_EYWA="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST $DB_NAME"
T64=$1
XPATH="/var/tmp/one/hooks/eywa/xpath.rb -b $T64"

ONE_VM_ID=`$XPATH /VM/ID`
ONE_UID=`$XPATH /VM/TEMPLATE/CONTEXT/ONE_UID`
ONE_GID=`$XPATH /VM/GID`
ONE_HID=`$XPATH /VM/HISTORY_RECORDS/HISTORY/HID`
ONE_ETH0_IP=`$XPATH /VM/TEMPLATE/CONTEXT/NIC/IP`
ONE_IS_EYWA=`$XPATH /VM/TEMPLATE/CONTEXT/IS_EYWA`
ONE_IS_VR=`$XPATH /VM/TEMPLATE/CONTEXT/IS_VR`
VR_PRI_IP="10.0.0.1"

QUERY_MC_ADDRESS=`$MYSQL_EYWA -e "select num,address from mc_address where uid='$ONE_UID'"`
VXLAN_G_N=`echo $QUERY_MC_ADDRESS | awk '{print $3}'` # VXLAN Group Number
VXLAN_G_A=`echo $QUERY_MC_ADDRESS | awk '{print $4}'` # VXLAN Group Address

if [ "$ONE_IS_EYWA" == "yes" ]; then
	if [ "$ONE_IS_VR" == "yes" ]; then
		if [ `sudo arptables -vnL | grep -c "\-j DROP -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1"` -eq 0 ]; then
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1 -j DROP
		fi
		if [ `sudo arptables -vnL | grep -c "\-j DROP -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1"` -eq 0 ]; then
			sudo arptables -A FORWARD -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1 -j DROP
		fi
		if [ `sudo arptables -vnL | grep -c "\-j DROP -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2"` -eq 0 ]; then
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2 -j DROP
		fi
	fi
fi

exit 0
