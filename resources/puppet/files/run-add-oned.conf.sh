#!/bin/bash

sed -i "/RESTRICTED_ATTR/ s/^/#/" /etc/one/oned.conf
if ! grep -q "EYWA Config" ${ONE_CONF}; then
	cat /home/vagrant/add-oned.conf >> ${ONE_CONF}
fi
