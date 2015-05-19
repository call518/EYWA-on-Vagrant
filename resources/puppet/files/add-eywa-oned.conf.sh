#!/bin/bash

ONE_CONF="/etc/one/oned.conf"

sed -i "/RESTRICTED_ATTR/ s/^/#/" /etc/one/oned.conf
if ! grep -q "EYWA Config" ${ONE_CONF}; then
	cat /home/vagrant/add-eywa-oned.conf >> ${ONE_CONF}
fi
