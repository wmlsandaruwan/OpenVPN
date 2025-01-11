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
   git clone https://github.com/your-repo-name/openvpn-setup.git
   cd openvpn-setup
