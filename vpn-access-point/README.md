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