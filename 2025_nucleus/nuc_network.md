Setting up the LAN connection for nuc

The main function of the nuc is to serve as a Roon server. This requires a LAN connection to connect to the NAS and wifi to connect to the various network players.
I kept NetworkManager and set the static IP for the LAN like this:
```
sudo nmcli connection modify "Wired connection 1" ipv4.addresses 192.168.1.130/24 ipv4.gateway 192.168.1.254 ipv4.method manual ipv6.method ignore ipv4.dns "192.168.1.254 1.1.1.1"
```
This assumes 192.168.1.254 is the IP address of the router and 192.168.1.130 is the desired IP address of the machine
Current devices and connections can be viewed by
```
ip link
nmcli connection show
```

Wifi was set up during ubuntu installation

