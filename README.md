
# OpenVPN Auto-Setup Script

## Overview
This script automates the setup of an OpenVPN server, complete with optional features like:
- Web server to host `.ovpn` configuration files with password protection.
- Easy creation of additional client configuration files.
- Dynamic addition of routes to the VPN server for network management.

The web interface is mobile-friendly and allows secure access to client configuration files.

---

## Features
- **OpenVPN Server Setup:** Fully automated installation and configuration of OpenVPN on your server.
- **Web Interface:** Password-protected, mobile-friendly web interface to download `.ovpn` files.
- **Client-to-Client Communication:** Option to enable communication between VPN clients.
- **Routing Configuration:** Add routes to the VPN server dynamically.
- **Customizable Settings:** Configure ports, protocols, and client details during setup.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/wmlsandaruwan/OpenVPN.git
   cd openvpn-setup
   chmod +x openvpn-setup.sh
   sudo ./openvpn-setup.sh
   ```

---

## Usage

### During Installation
The script will prompt you to:
- Set VPN port, protocol, and network settings.
- Enable and configure a web server for hosting `.ovpn` files.
- Create client configuration files.
- Add routes for additional subnets.

### Post-Installation Options

#### Adding New Clients
Re-run the script to create additional client configuration files:
```bash
sudo ./openvpn-setup.sh
```
Select the option to create a new client.

#### Adding Routes Dynamically
The script also allows dynamic addition of routes for new subnets to the VPN.

---

## Web Interface
If enabled during setup:
- Access the `.ovpn` files via the web interface:
  ```
  http://YOUR_SERVER_IP:PORT
  ```
- Authenticate using the username `vpnadmin` and the password set during installation.

---

## Requirements
- Ubuntu/Debian-based server.
- Internet access for package installation.

---

## Contributing
Contributions are welcome! If you have suggestions for improvements or find any issues, feel free to:
1. Open an issue in the repository.
2. Submit a pull request with your changes.

---

## Support
If you encounter any issues or need help with the script:
1. Check the repository's issues section for existing solutions.
2. Open a new issue describing your problem in detail.

We aim to provide support to the best of our ability but cannot guarantee immediate responses.

---

## Disclaimer
This script is provided as-is without any warranties or guarantees. Use it at your own risk. The authors are not responsible for:
1. Any data loss, downtime, or server issues caused by this script.
2. Security risks or breaches resulting from improper use or configuration.
3. Failure to comply with laws or regulations governing VPN use in your country.

Ensure you understand the implications of running a VPN server and comply with local laws.

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
