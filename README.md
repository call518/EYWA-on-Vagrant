# Description

EYWA PoC, OpenNebula on Vagrant Environment

## (Note)

* On MS-Windows family, may be "\^M" EOL troube...
* (Recommended) Before "Git Clone", Running "git config --global core.autocrlf true"

# EYWA Architecture

![Architecture](etc-files/Architecture.png)

# Dashboard

![Dashboard](etc-files/Dashboard.png)

# Installation

## Build Master Node (Front-end)

(Note) When connect SSH, ignore "*** System restart required ***" message.

```bash
host> vagrant up master
host> vagrant ssh master
master> sudo /home/vagrant/config-one-env.sh
```

### (Note) config-one-env.sh

* Create Virtual-Network
* Create Image (CentOS 6.5 x86_64)
* Create Template (CentOS-6.5_64)

## Build Slave Nodes

```bash
host> vagrant up slave-1
host> vagrant up slave-2
```

## (Option) Using Desktop VNC

* Connecting /w VNC

```
[master]
VNC Address: {Vagrant-Host-IP}:55910

[slave-1]
VNC Address: {Vagrant-Host-IP}:55911

[slave-2]
VNC Address: {Vagrant-Host-IP}:55912
```

## Web-UI
  * http://{Host-IP}:9869
  * Admin ID/PW: oneadmin / passw0rd

## PoC Scenario

+ Log in to Web-UI, by "oneadmin" user.
+ Go to "System" Tab -> "Users" Tab.
+ Click "+" Button.
+ Create "oneadmin" User. (Password is that you want.)
* Default Templates is generated. (in "Templates" Tab)
+ EYWA-Virutal-Router(VR-1) is automatic launched. (in "Virtual Machines" Tab)
* When VR-1 is up, Create EYWA-VM(VM-1).
* Add VR-2 for LB/HA
* Add VM-2.
* Test Ping, to/on all Nodes.

### SSH Connect to VM

```
on master or slave-{n}

ssh -i /var/lib/one/.ssh/id_rsa root@{vm_ip_address}
```

## APPENDIX

* OpenNebula's VNC Console is not supported. Because of Port Forwarding (>5900, Dynamic)
