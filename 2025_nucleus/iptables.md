Complete OpenVPN + iptables Setup Workflow
1. Backup Current Configuration
bash# Create timestamped backup
sudo iptables-save > ~/iptables-backup-$(date +%Y%m%d-%H%M%S).rules
echo "Backup created: ~/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"
ls -la ~/iptables-backup-*.rules
2. Clean and Configure iptables
bash# Clean existing rules (removes old ufw chains)
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X

# Set default policies
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
3. Add Security Rules
bash# Allow established and related connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback traffic
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow local subnets (covers most services including Roon, xrdp locally)
sudo iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -s 192.168.68.0/24 -j ACCEPT

# Allow specific services from anywhere
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT      # SSH
sudo iptables -A INPUT -p tcp --dport 3389 -j ACCEPT    # xrdp (if needed from internet)
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT    # OpenVPN

# Drop everything else
sudo iptables -A INPUT -j DROP
4. Add OpenVPN NAT Rules
bash# Enable IP forwarding for OpenVPN
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Add NAT rule for OpenVPN clients (adjust interface name if needed)
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE

# Allow forwarding for OpenVPN
sudo iptables -A FORWARD -i tun+ -j ACCEPT
sudo iptables -A FORWARD -o tun+ -j ACCEPT
5. Verify Configuration
bash# Check INPUT rules
sudo iptables -L INPUT -n --line-numbers

# Check NAT rules
sudo iptables -t nat -L -n -v

# Check if IP forwarding is enabled
cat /proc/sys/net/ipv4/ip_forward
6. Make Rules Persistent
bash# Install iptables-persistent
sudo apt update && sudo apt install iptables-persistent -y

# Save current rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

# Or use netfilter-persistent
sudo netfilter-persistent save
7. Test Your Setup
bash# Test SSH (should work)
ssh user@your-server-ip

# Test local services (should work from local network)
# - Roon should be accessible from local devices
# - xrdp should work from local network

# Check OpenVPN status
sudo systemctl status openvpn-server@server
8. If Something Goes Wrong - Rollback
bash# Restore from backup
sudo iptables-restore < ~/iptables-backup-[timestamp].rules
What This Setup Achieves

SSH (22): Accessible from anywhere
OpenVPN (1194): Accessible from anywhere
xrdp (3389): Accessible from anywhere (remove if you only want local access)
All local services: Accessible from 192.168.1.x and 192.168.68.x networks
Roon, Deluge, etc.: Work normally from local network
Secure: Everything else is blocked

Optional: Remove xrdp Internet Access
If you only want xrdp accessible locally, remove this line:
bashsudo iptables -D INPUT -p tcp --dport 3389 -j ACCEPT
Your local subnet rules will still allow xrdp access from your local networks.