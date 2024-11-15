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

## Requirements

- Raspberry Pi 4 (recommended) or Raspberry Pi 3
- Raspbian/Raspberry Pi OS (Debian Bullseye or newer)
- Compatible WiFi adapter (built-in WiFi works)
- Active internet connection
- VPN subscription with OpenVPN configuration files

## Troubleshooting

Check service status:
```bash
# Check VPN connection
systemctl status openvpn@client

# Check WiFi access point
systemctl status hostapd

# Check DHCP server
systemctl status dnsmasq

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# View iptables rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

Common issues:

1. **No WiFi network visible**
   - Check hostapd status: `systemctl status hostapd`
   - Verify WiFi interface: `iwconfig`
   - Check hostapd configuration: `cat /etc/hostapd/hostapd.conf`

2. **Can't connect to WiFi**
   - Verify password in hostapd.conf
   - Check system logs: `journalctl -u hostapd`

3. **No internet access**
   - Check VPN connection: `systemctl status openvpn@client`
   - Verify IP forwarding: `cat /proc/sys/net/ipv4/ip_forward`
   - Check iptables rules
   - Verify DNS resolution: `cat /etc/resolv.conf`

## Security Considerations

- Change the default WiFi password in `hostapd.conf`
- Keep your VPN credentials secure
- Regularly update your system: `sudo apt update && sudo apt upgrade`
- Monitor system logs for unusual activity

## Customization

### Changing WiFi Settings
Edit `/etc/hostapd/hostapd.conf` to modify:
- SSID (network name)
- Password
- Channel
- WiFi mode (a/b/g/n)

### Modifying Network Range
Edit `/etc/dnsmasq.conf` to change:
- DHCP range
- Lease time
- DNS settings

## Contributing

Feel free to submit issues and pull requests to improve this project.

## License

This project is released under the MIT License. See the LICENSE file for details.