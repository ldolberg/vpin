from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
import subprocess
import os
import json
import psutil
import time

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'  # Change this to a secure random key

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Simple user class for authentication
class User(UserMixin):
    def __init__(self, id):
        self.id = id

# Default admin user (you should change this in production)
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin"  # Change this!

@login_manager.user_loader
def load_user(user_id):
    return User(user_id)

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            user = User(username)
            login_user(user)
            return redirect(url_for('index'))
        flash('Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/api/status')
@login_required
def get_status():
    vpn_status = subprocess.run(['systemctl', 'is-active', 'openvpn'], 
                              capture_output=True, text=True).stdout.strip()
    hostapd_status = subprocess.run(['systemctl', 'is-active', 'hostapd'], 
                                  capture_output=True, text=True).stdout.strip()

    inet_status = json.loads(subprocess.run(['curl', 'ipinfo.io'], capture_output=True, text=True).stdout.strip())

    # Get connected clients
    clients = []
    try:
        leases = open('/var/lib/misc/dnsmasq.leases').readlines()
        for lease in leases:
            parts = lease.split()
            clients.append({
                'mac': parts[1],
                'ip': parts[2],
                'hostname': parts[3]
            })
    except:
        pass

    return jsonify({
        'vpn': vpn_status == 'active',
        'wifi': hostapd_status == 'active',
        'clients': clients,
        'cpu_usage': psutil.cpu_percent(),
        'memory_usage': psutil.virtual_memory().percent,
        "inet": inet_status
    })

@app.route('/api/vpn/<action>', methods=['POST'])
@login_required
def vpn_control(action):
    if action == 'start':
        subprocess.run(['systemctl', 'start', 'openvpn-client@client.service'])
    elif action == 'stop':
        subprocess.run(['systemctl', 'stop', 'openvpn-client@client.service'])
    elif action == 'restart':
        subprocess.run(['systemctl', 'restart', 'openvpn-client@client.service'])
    return jsonify({'status': 'success'})

@app.route('/api/wifi/<action>', methods=['POST'])
@login_required
def wifi_control(action):
    if action == 'start':
        subprocess.run(['systemctl', 'start', 'hostapd'])
    elif action == 'stop':
        subprocess.run(['systemctl', 'stop', 'hostapd'])
    elif action == 'restart':
        subprocess.run(['systemctl', 'restart', 'hostapd'])
    return jsonify({'status': 'success'})

@app.route('/api/settings', methods=['GET', 'POST'])
@login_required
def settings():
    if request.method == 'POST':
        data = request.get_json()
        
        # Update hostapd configuration
        if 'wifi' in data:
            with open('/etc/hostapd/hostapd.conf', 'r') as f:
                config = f.read()
            
            config = config.replace(f'ssid=.*', f'ssid={data["wifi"]["ssid"]}')
            config = config.replace(f'wpa_passphrase=.*', 
                                 f'wpa_passphrase={data["wifi"]["password"]}')
            
            with open('/etc/hostapd/hostapd.conf', 'w') as f:
                f.write(config)
        
        # Update OpenVPN configuration
        if 'vpn' in data:
            with open('/etc/openvpn/client/client.conf', 'w') as f:
                f.write(data['vpn']['config'])
        
        return jsonify({'status': 'success'})
    
    # GET request - return current settings
    with open('/etc/hostapd/hostapd.conf', 'r') as f:
        hostapd_config = f.read()
    
    with open('/etc/openvpn/client/client.conf', 'r') as f:
        vpn_config = f.read()
    
    return jsonify({
        'wifi': {
            'ssid': next(line.split('=')[1] for line in hostapd_config.splitlines() 
                        if line.startswith('ssid=')),
            'password': next(line.split('=')[1] for line in hostapd_config.splitlines() 
                           if line.startswith('wpa_passphrase='))
        },
        'vpn': {
            'config': vpn_config
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080) 