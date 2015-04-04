#!/bin/bash

mount -t nfs -o soft,intr,rsize=8192,wsize=8192,noauto master:/var/lib/one/datastores /var/lib/one/datastores
