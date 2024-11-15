#!/bin/bash

# Create project directory structure
mkdir -p vpn-access-point/{config/{hostapd,dnsmasq,network,openvpn},scripts,systemd}

# Create hostapd configuration
cat > vpn-access-point/config/hostapd/hostapd.conf << 'EOL'
interface=wlan0
driver=nl80211
ssid=MyVPNAccessPoint
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=YourSecurePassword
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

# Create dnsmasq configuration
cat > vpn-access-point/config/dnsmasq/dnsmasq.conf << 'EOL'
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
domain=wlan
address=/gw.wlan/192.168.4.1
EOL

# Create network interfaces configuration
cat > vpn-access-point/config/network/interfaces << 'EOL'
# The loopback network interface
auto lo
iface lo inet loopback

# Ethernet
auto eth0
iface eth0 inet dhcp

# WiFi
auto wlan0
iface wlan0 inet static
    address 192.168.4.1
    netmask 255.255.255.0
EOL

# Create VPN setup script
cat > vpn-access-point/scripts/vpn-setup.sh << 'EOL'
#!/bin/bash

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Clear existing iptables rules
iptables -F
iptables -t nat -F

# Set up NAT
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Start OpenVPN
systemctl start openvpn@client
EOL

# Create OpenVPN client configuration
cat > vpn-access-point/config/openvpn/client.conf << 'EOL'
client
dev tun
proto udp
remote your-vpn-server.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
cipher AES-256-CBC
verb 3
EOL

# Create systemd service file
cat > vpn-access-point/systemd/vpn-access-point.service << 'EOL'
[Unit]
Description=VPN WiFi Access Point
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/vpn-setup.sh
ExecStart=/usr/sbin/hostapd /etc/hostapd/hostapd.conf
ExecStart=/usr/sbin/dnsmasq

[Install]
WantedBy=multi-user.target
EOL

# Create installation script
cat > vpn-access-point/install.sh << 'EOL'
#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Install required packages
apt-get update
apt-get install -y hostapd dnsmasq openvpn iptables-persistent

# Copy configuration files
cp config/hostapd/hostapd.conf /etc/hostapd/
cp config/dnsmasq/dnsmasq.conf /etc/dnsmasq.conf
cp config/network/interfaces /etc/network/
cp config/openvpn/client.conf /etc/openvpn/
cp scripts/vpn-setup.sh /usr/local/bin/
cp systemd/vpn-access-point.service /etc/systemd/system/

# Make vpn-setup.sh executable
chmod +x /usr/local/bin/vpn-setup.sh

# Enable services
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
systemctl enable vpn-access-point

# Configure hostapd
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd

# Save iptables rules
netfilter-persistent save

echo "Installation complete!"
echo "Please:"
echo "1. Update the VPN configuration in /etc/openvpn/client.conf"
echo "2. Place your VPN certificates in the appropriate location"
echo "3. Update the WiFi password in /etc/hostapd/hostapd.conf"
echo "4. Reboot your system"
EOL

# Create README file
cat > vpn-access-point/README.md << 'EOL'
# Raspberry Pi VPN Access Point

This project turns a Raspberry Pi 4 into a WiFi access point that routes all traffic through a VPN connection.

## Installation

1. Clone this repository
2. Update the VPN configuration in `config/openvpn/client.conf` with your VPN provider's details
3. Place your VPN certificates and keys in the `config/openvpn/` directory
4. Update the WiFi password in `config/hostapd/hostapd.conf`
5. Run the installation script as root:
   ```bash
   sudo ./install.sh
   ```
6. Reboot your Raspberry Pi

## Configuration Files

- `config/hostapd/hostapd.conf`: WiFi access point configuration
- `config/dnsmasq/dnsmasq.conf`: DHCP server configuration
- `config/network/interfaces`: Network interfaces configuration
- `config/openvpn/client.conf`: OpenVPN client configuration
- `scripts/vpn-setup.sh`: VPN and routing setup script
- `systemd/vpn-access-point.service`: Systemd service file

## Default Settings

- WiFi SSID: MyVPNAccessPoint
- IP Range: 192.168.4.0/24
- DHCP Range: 192.168.4.2 - 192.168.4.20

## Troubleshooting

Check service status:
EOL 