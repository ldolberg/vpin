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