#!/bin/bash

# Default Variables
DEFAULT_VPN_PORT=443
DEFAULT_VPN_PROTOCOL="tcp"
DEFAULT_VPN_SUBNET="10.8.0.0"
DEFAULT_VPN_NETMASK="255.255.255.0"
DEFAULT_INTERFACE="eth0"
DEFAULT_COUNTRY="US"
DEFAULT_PROVINCE="California"
DEFAULT_CITY="San Francisco"
DEFAULT_ORG="MyVPN"
DEFAULT_EMAIL="admin@myvpn.com"
DEFAULT_OU="MyVPNUnit"
DEFAULT_WEB_PORT=8080

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to create a new client configuration
create_client_config() {
    local client_name=$(get_input "Enter the client name for the new configuration" "client")
    local client_config="/var/www/html/${client_name}.ovpn"

    echo "Generating client configuration for ${client_name}..."
    cat <<EOF > $client_config
client
dev tun
proto $VPN_PROTOCOL
remote YOUR_SERVER_IP $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
key-direction 1
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF

    echo "Client configuration created: ${client_config}"
    echo "Replace YOUR_SERVER_IP in the configuration file with the server's public IP."
}

# Ensure system dependencies are resolved
fix_dependencies() {
    echo "Fixing package dependencies..."
    sudo apt remove -y iptables-persistent netfilter-persistent || true
    sudo apt --fix-broken install -y
    sudo apt update && sudo apt upgrade -y
}

# Prompt user for settings
VPN_PORT=$(get_input "Enter the VPN port" $DEFAULT_VPN_PORT)
VPN_PROTOCOL=$(get_input "Enter the VPN protocol (tcp/udp)" $DEFAULT_VPN_PROTOCOL)
VPN_SUBNET=$(get_input "Enter the VPN subnet" $DEFAULT_VPN_SUBNET)
VPN_NETMASK=$(get_input "Enter the VPN netmask" $DEFAULT_VPN_NETMASK)
VPN_INTERFACE=$(get_input "Enter the network interface name" $DEFAULT_INTERFACE)

# Prompt user for EasyRSA variables
EASYRSA_COUNTRY=$(get_input "Enter the country for the certificate" $DEFAULT_COUNTRY)
EASYRSA_PROVINCE=$(get_input "Enter the province for the certificate" $DEFAULT_PROVINCE)
EASYRSA_CITY=$(get_input "Enter the city for the certificate" $DEFAULT_CITY)
EASYRSA_ORG=$(get_input "Enter the organization name for the certificate" $DEFAULT_ORG)
EASYRSA_EMAIL=$(get_input "Enter the email address for the certificate" $DEFAULT_EMAIL)
EASYRSA_OU=$(get_input "Enter the organizational unit for the certificate" $DEFAULT_OU)

# Prompt user for web server setup
ENABLE_WEB_SERVER=$(get_input "Enable web server to host .ovpn files? (yes/no)" "yes")
if [[ "$ENABLE_WEB_SERVER" == "yes" ]]; then
    WEB_PORT=$(get_input "Enter the port for the web server" $DEFAULT_WEB_PORT)
    WEB_PASSWORD=$(get_input "Set a password for accessing the web interface" "vpnadmin")
fi

# Prompt user for additional settings
ENABLE_CLIENT_TO_CLIENT=$(get_input "Enable client-to-client communication? (yes/no)" "no")
ROUTE_CLIENT_NETWORK=$(get_input "Enable routing to the client's local network? (yes/no)" "no")
if [[ "$ROUTE_CLIENT_NETWORK" == "yes" ]]; then
    CLIENT_NETWORK=$(get_input "Enter the client's local network (e.g., 192.168.1.0)" "192.168.1.0")
    CLIENT_NETMASK=$(get_input "Enter the client's subnet mask (e.g., 255.255.255.0)" "255.255.255.0")
fi

ADD_ADDITIONAL_SUBNETS=$(get_input "Do you want to add additional subnets to route through the VPN? (yes/no)" "no")
ADDITIONAL_SUBNETS=()
if [[ "$ADD_ADDITIONAL_SUBNETS" == "yes" ]]; then
    while true; do
        ADD_SUBNET=$(get_input "Enter the additional subnet to route (e.g., 192.168.2.0)" "")
        ADD_NETMASK=$(get_input "Enter the subnet mask for $ADD_SUBNET (e.g., 255.255.255.0)" "255.255.255.0")
        ADDITIONAL_SUBNETS+=("$ADD_SUBNET $ADD_NETMASK")
        echo "Adding route for $ADD_SUBNET/$ADD_NETMASK..."
        ADD_MORE=$(get_input "Do you want to add another subnet? (yes/no)" "no")
        if [[ "$ADD_MORE" != "yes" ]]; then
            break
        fi
    done
fi

VPN_SERVER_CONF="/etc/openvpn/server.conf"

# Confirm settings with user
echo "\nUsing the following settings:"
echo "VPN Port: $VPN_PORT"
echo "VPN Protocol: $VPN_PROTOCOL"
echo "VPN Subnet: $VPN_SUBNET"
echo "VPN Netmask: $VPN_NETMASK"
echo "Network Interface: $VPN_INTERFACE"
echo "Certificate Country: $EASYRSA_COUNTRY"
echo "Certificate Province: $EASYRSA_PROVINCE"
echo "Certificate City: $EASYRSA_CITY"
echo "Certificate Organization: $EASYRSA_ORG"
echo "Certificate Email: $EASYRSA_EMAIL"
echo "Certificate Organizational Unit: $EASYRSA_OU"
if [[ "$ENABLE_WEB_SERVER" == "yes" ]]; then
    echo "Web Server Enabled: Yes"
    echo "Web Server Port: $WEB_PORT"
    echo "Web Interface Password: $WEB_PASSWORD"
fi
echo
read -p "Do you want to continue with these settings? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Setup aborted."
    exit 1
fi

# Begin OpenVPN setup
fix_dependencies
sudo apt install -y openvpn easy-rsa iptables-persistent ufw apache2 apache2-utils

# Configure Apache Web Server
if [[ "$ENABLE_WEB_SERVER" == "yes" ]]; then
    echo "Configuring Apache Web Server..."
    sudo mkdir -p /var/www/html
    echo "<html><body><h1>OpenVPN Configuration Files</h1><ul>" > /var/www/html/index.html
    for file in /var/www/html/*.ovpn; do
        echo "<li><a href='$(basename "$file")'>$(basename "$file")</a></li>" >> /var/www/html/index.html
    done
    echo "</ul></body></html>" >> /var/www/html/index.html
    echo "$WEB_PASSWORD" | sudo htpasswd -c -i /etc/apache2/.htpasswd vpnadmin
    sudo sed -i "s|<Directory /var/www/>|<Directory /var/www/html/>
    AuthType Basic
    AuthName \"Restricted Access\"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user|" /etc/apache2/sites-available/000-default.conf
    sudo ufw allow $WEB_PORT/tcp
    sudo systemctl restart apache2
fi

# Create server configuration
cat <<EOF > $VPN_SERVER_CONF
port $VPN_PORT
proto $VPN_PROTOCOL
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
tls-auth /etc/openvpn/ta.key 0
server $VPN_SUBNET $VPN_NETMASK
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

# Add additional settings if enabled
if [[ "$ENABLE_CLIENT_TO_CLIENT" == "yes" ]]; then
    echo "client-to-client" >> $VPN_SERVER_CONF
fi
if [[ "$ROUTE_CLIENT_NETWORK" == "yes" ]]; then
    echo "push \"route $CLIENT_NETWORK $CLIENT_NETMASK\"" >> $VPN_SERVER_CONF
fi
if [[ "$ADD_ADDITIONAL_SUBNETS" == "yes" ]]; then
    for SUBNET in "${ADDITIONAL_SUBNETS[@]}"; do
        SUBNET_ADDR=$(echo $SUBNET | cut -d' ' -f1)
        SUBNET_MASK=$(echo $SUBNET | cut -d' ' -f2)
        echo "push \"route $SUBNET_ADDR $SUBNET_MASK\"" >> $VPN_SERVER_CONF
    done
fi

# Enable OpenVPN service
sudo mkdir -p /etc/openvpn
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server

# Final Instructions
echo "Setup complete!"
if [[ "$ENABLE_WEB_SERVER" == "yes" ]]; then
    echo "Web interface is available at: http://YOUR_SERVER_IP:$WEB_PORT"
    echo "Use the username 'vpnadmin' and the password you set to access the configuration files."
fi
