# Description

EYWA PoC, on Vagrant Environment

# Dashboard

![Dashboard](etc-files/dashboard.png)

# Prepair OpenNebula Env.

## Post-Installation

```bash
host> vagrant ssh master
master> sudo /home/vagrant/config-one-env.sh
```

## Login Web Console: http://{Host-IP}:9869
  * Admin ID/PW: oneadmin / passw0rd

## Architecture of EYWA

![Architecture](etc-files/architecture.png)

## (Note)

* VNC Console is not supported. Because of Port Forwarding (>5900, Random)
