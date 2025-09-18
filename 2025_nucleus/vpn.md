PiVPN installation is possible with Ubuntu, but it messed up my network.

I therefore uninstalled it and went with an OpenVPN install

OpenVPN Server Setup on Ubuntu
This guide sets up a barebones OpenVPN server that generates .ovpn client files, with fixes for dual network interfaces.
Install and Setup PKI
bash# Install required packages
sudo apt update && sudo apt install openvpn easy-rsa

# Setup PKI and certificates
mkdir ~/vpn && cd ~/vpn
cp -r /usr/share/easy-rsa/* .
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey secret ta.key
Server Configuration
bash# Copy certificates to OpenVPN directory
sudo cp pki/{ca.crt,issued/server.crt,private/server.key,dh.pem} /etc/openvpn/server/
sudo cp ta.key /etc/openvpn/server/

# Create server configuration
sudo tee /etc/openvpn/server/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 9.9.9.9"
tls-auth ta.key 0
user nobody
group nogroup
persist-key
persist-tun
verb 3
EOF
Enable Networking and Firewall
bash# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Setup NAT for dual interfaces (Ethernet + WiFi)
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o enp0s25 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o wlp2s0 -j MASQUERADE

# Allow OpenVPN through firewall
sudo ufw allow 1194/udp

# Make iptables rules persistent
sudo apt install iptables-persistent -y
sudo iptables-save | sudo tee /etc/iptables/rules.v4
Start OpenVPN Service
bash# Enable and start OpenVPN
sudo systemctl enable openvpn-server@server
sudo systemctl start openvpn-server@server

# Check status
sudo systemctl status openvpn-server@server
Generate Client Configuration
bash# Create first client certificate
cd ~/vpn
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Get server public IP
SERVER_IP=$(curl -4 -s ifconfig.me)

# Generate client .ovpn file with proper key-direction
cat > client1.ovpn <<EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
key-direction 1
<ca>
$(cat pki/ca.crt)
</ca>
<cert>
$(cat pki/issued/client1.crt)
</cert>
<key>
$(cat pki/private/client1.key)
</key>
<tls-auth>
$(cat ta.key)
</tls-auth>
EOF

echo "Client configuration saved as client1.ovpn"
Add Additional Clients
bash# Generate new client (replace client2 with desired name)
cd ~/vpn
./easyrsa gen-req client2 nopass
./easyrsa sign-req client client2

# Create .ovpn file for new client
SERVER_IP=$(curl -4 -s ifconfig.me)
CLIENT_NAME="client2"

cat > ${CLIENT_NAME}.ovpn <<EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
key-direction 1
<ca>
$(cat pki/ca.crt)
</ca>
<cert>
$(cat pki/issued/${CLIENT_NAME}.crt)
</cert>
<key>
$(cat pki/private/${CLIENT_NAME}.key)
</key>
<tls-auth>
$(cat ta.key)
</tls-auth>
EOF
Troubleshooting Commands
bash# Check server status
sudo systemctl status openvpn-server@server
sudo journalctl -u openvpn-server@server -f

# Verify NAT rules
sudo iptables -t nat -L POSTROUTING -v -n | grep MASQUERADE

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Test client connection with verbose output
sudo openvpn --config client1.ovpn --verb 4
Notes

Server uses tls-auth ta.key 0, client uses key-direction 1 to fix HMAC authentication errors
NAT masquerade rules set for both Ethernet (enp0s25) and WiFi (wlp2s0) interfaces
DNS configured to use Quad9 (9.9.9.9)
Client .ovpn files can be imported into any OpenVPN client
All traffic routes through the VPN server's public IP when connected