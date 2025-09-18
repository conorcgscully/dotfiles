#!/bin/bash
# Initial setup for nuc 
# On a fresh Ubuntu install (assuming sudo user conor exists)
# sudo apt install -y git
# git clone https://github.com/conorcgscully/dotfiles.git
# cd dotfiles
# ./install.sh

set -e

# Change default SSH port to 42279
sudo apt update -y && sudo apt upgrade -y

sudo apt install -y openssh-server
#sudo sed -i 's/Port 22/Port 42279/' /etc/ssh/ssh_config

# Restart SSH service to apply changes
sudo systemctl restart ssh

# NFS
sudo apt install -y nfs-common
sudo mkdir -p /mnt/haydn
sudo mount -t nfs 192.168.1.103:/volume2/NAS-Haydn /mnt/haydn # TODO

sudo apt install -y xrdp
#WaylandEnable=false
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

echo "gnome-session" > ~/.xsession
chmod +x ~/.xsession
sudo systemctl restart gdm3
sudo chown root:ssl-cert /etc/xrdp/key.pem
sudo chmod 640 /etc/xrdp/key.pem
sudo systemctl restart xrdp

sudo apt install -y ufw
sudo ufw allow 22
sudo ufw allow 3389
sudo ufw enable

sudo apt install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo sed -i 's/^\s*maxretry\s*=.*/maxretry = 3/' /etc/fail2ban/jail.local

# Change bantime to -1
sudo sed -i 's/^\s*bantime\s*=.*/bantime = -1/' /etc/fail2ban/jail.local

# Restart Fail2Ban to apply changes
sudo systemctl restart fail2ban
sudo systemctl status fail2ban

# Roon
sudo apt install -y curl ffmpeg cifs-utils lbzip2
curl -O -L https://download.roonlabs.com/builds/roonserver-installer-linuxx64.sh
sudo chmod +x roonserver-installer-linuxx64.sh
sudo ./roonserver-installer-linuxx64.sh


# Sleep and WOL [not currently using]
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1200

