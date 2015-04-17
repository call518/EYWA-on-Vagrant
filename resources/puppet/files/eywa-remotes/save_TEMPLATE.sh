#!/bin/bash

VM_ID=$1
TEMPLATE=$2
SAVE_DIR="/var/lib/one/vms/$VM_ID"

echo $TEMPLATE > $SAVE_DIR/TEMPLATE

#XPATH="/var/tmp/one/hooks/eywa/xpath.rb -b $TEMPLATE"
#$XPATH > $SAVE_DIR/TEMPLATE.xpath
