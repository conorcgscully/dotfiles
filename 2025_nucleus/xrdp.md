# XRDP + XFCE4 Setup & Troubleshooting Guide

This guide documents the steps I took to fix XRDP not showing a desktop on my Linux NUC.  
Symptoms included:
- XRDP login succeeded but no desktop appeared.
- Logs showed errors like:
  - `Window manager exited quickly`
  - `scp_process_msg failed`
  - XFCE would not start over XRDP.

---

## 1. Install XFCE4 and required packages

```bash
sudo apt update
sudo apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils


Notes:

xfce4 is the desktop environment.

dbus-x11 is critical — without it, XFCE sessions launched via XRDP will fail immediately.

xfce4-goodies and x11-xserver-utils add useful extras.

2. Configure XRDP to start XFCE4

Edit the XRDP startup script:

sudo nano /etc/xrdp/startwm.sh


Replace everything in the file with:

#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

exec startxfce4


Then make it executable:

sudo chmod +x /etc/xrdp/startwm.sh

3. Clean up old configs (optional but recommended)

Remove conflicting session configs:

mv ~/.xsession ~/.xsession.bak 2>/dev/null
mv ~/.xinitrc ~/.xinitrc.bak 2>/dev/null

4. Restart XRDP
sudo systemctl restart xrdp xrdp-sesman

5. Connect via Remote Desktop

Use the server’s LAN IP.

Login with your Linux username and password.

XFCE desktop should load normally.

6. Troubleshooting

If session closes immediately:

Check logs:

tail -n 50 /var/log/xrdp-sesman.log
tail -n 50 ~/.xorgxrdp.*.log


If you see:

Window manager exited quickly → likely missing dbus-x11.

/usr/lib/xorg/Xorg.wrap: Only console users are allowed to run the X server → normal if testing startxfce4 over SSH; ignore it.

Summary

The key fixes were:

Install dbus-x11.

Simplify /etc/xrdp/startwm.sh to only run startxfce4.

Restart XRDP and clear old session files.

After these changes, XFCE4 works reliably over RDP.