# Description

OpenNebula on Vagrant Environment

# Dashboard

![Dashboard](etc-files/dashboard.png)

# Prepair OpenNebula Env.

## Post-Installation

```bash
host> vagrant ssh master
master> sudo /home/vagrant/config-one-env.sh
```

* (Note) You will need to wait until the image is READY to be used.
  * in "Virtual Resource" Tab -> "Images" Tab

## Login Web Console: http://{Host-IP}:9869
  * Admin ID/PW: oneadmin / passw0rd

## (Note)

* VNC Console is not supported. Because of Port Forwarding (>5900, Random)
