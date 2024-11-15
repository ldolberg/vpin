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