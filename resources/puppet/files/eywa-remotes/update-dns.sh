#!/bin/bash

#DB_HOST="192.168.33.11"
#DB_NAME="eywa"
#DB_USER="eywa"
#DB_PASS="1234"
#MYSQL_EYWA="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST $DB_NAME"
T64=$2
XPATH="/var/tmp/one/hooks/eywa/xpath.rb -b $T64"

ONE_ETH0_IP=`$XPATH /VM/TEMPLATE/NIC/IP`
ONE_IS_EYWA=`$XPATH /VM/TEMPLATE/CONTEXT/IS_EYWA`
ONE_IS_VR=`$XPATH /VM/TEMPLATE/CONTEXT/IS_VR`

NS_BIN="/usr/bin/nsupdate"

SERVER="192.168.33.11"
#WORK_IP=$3
#if [ "$ONE_IS_EYWA" == "yes" ]; then
#	if [ "$ONE_IS_VR" == "yes" ]; then
#		FQDN_HEAD="EYWA-VR"
#	else
#		FQDN_HEAD="EYWA-VM"
#	fi
#else
#	FQDN_HEAD="Public-VM"
#fi
FQDN_HEAD="VM"
ZONE="test.org"
WORK_IP=$ONE_ETH0_IP
WORK_IP_1=`echo $WORK_IP | awk -F'.' '{print $1}'`
WORK_IP_2=`echo $WORK_IP | awk -F'.' '{print $2}'`
WORK_IP_3=`echo $WORK_IP | awk -F'.' '{print $3}'`
WORK_IP_4=`echo $WORK_IP | awk -F'.' '{print $4}'`

WORK_FQDN="$FQDN_HEAD-$WORK_IP_1-$WORK_IP_2-$WORK_IP_3-$WORK_IP_4.$ZONE"
WORK_PTR_IP="$WORK_IP_4-$WORK_IP_3-$WORK_IP_2-$WORK_IP_1"

function usage() {
    echo
    echo "  Usage : $0 {create|delete} %TEMPLATE%"
    echo
    exit 1
}

#update add ${WORK_IP_4}.${WORK_IP_3}.${WORK_IP_2}.${WORK_IP_1}.in-addr.arpa 60 PTR ${WORK_FQDN}.
#update delete ${WORK_IP_4}.${WORK_IP_3}.${WORK_IP_2}.${WORK_IP_1}.in-addr.arpa
case "$1" in
    create)
${NS_BIN} << EOF
server ${SERVER}
update add ${WORK_FQDN}. 60 IN A ${WORK_IP}
send
server ${SERVER}
update add ${WORK_PTR_IP}.in-addr.arpa 60 PTR ${WORK_FQDN}.
send
EOF
        ;;
    delete)
${NS_BIN} << EOF
server ${SERVER}
update delete ${WORK_FQDN} IN A ${WORK_IP}
send
server ${SERVER}
update delete ${WORK_PTR_IP}.in-addr.arpa
send
EOF
        ;;
    *)
        usage
        ;;
esac

exit 0
