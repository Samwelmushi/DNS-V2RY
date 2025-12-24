# DNSTT+V2RAY 🚀

<div align="center">

```
  ██████╗ ███╗   ██╗███████╗████████╗████████╗   ██╗   ██╗██████╗ 
  ██╔══██╗████╗  ██║██╔════╝╚══██╔══╝╚══██╔══╝   ██║   ██║╚════██╗
  ██║  ██║██╔██╗ ██║███████╗   ██║      ██║█████╗██║   ██║ █████╔╝
  ██║  ██║██║╚██╗██║╚════██║   ██║      ██║╚════╝╚██╗ ██╔╝██╔═══╝ 
  ██████╔╝██║ ╚████║███████║   ██║      ██║       ╚████╔╝ ███████╗
  ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝      ╚═╝        ╚═══╝  ╚══════╝
```

### High-Speed DNS Tunnel + V2Ray Server

**MADE BY THE KING** 👑

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

</div>

---

## 📖 Overview

**DNSTT+V2RAY** is a powerful automated installation script that sets up a high-performance DNS tunneling server combined with V2Ray proxy. This solution is perfect for bypassing network restrictions while maintaining excellent speed (3-5 Mbps+) through optimized configurations.

### ✨ Key Features

- 🚀 **High-Speed Performance**: Optimized for 3-5 Mbps+ speeds
- 🔧 **Custom MTU Configuration**: Default 512 bytes with easy customization (512/800/1200)
- 🎯 **One-Click Installation**: Fully automated setup process
- 📋 **Easy Copy & Paste**: All configuration details ready to copy
- 🔐 **Multiple Protocols**: VMess, VLess, and Trojan support
- ⚡ **System Optimization**: BBR congestion control and TCP optimizations
- 📊 **Service Management**: Start, stop, restart services with ease
- 📝 **Detailed Logging**: View and monitor all service logs
- 💾 **Backup Support**: Save and restore configurations
- 🔄 **Auto-Update**: Update script directly from GitHub
- 🎨 **Beautiful Interface**: Colorful and user-friendly menu system

---

## 🖥️ System Requirements

### Supported Operating Systems
- Ubuntu 18.04 / 20.04 / 22.04 / 24.04
- Debian 9 / 10 / 11 / 12
- CentOS 7 / 8
- RHEL 7 / 8 / 9
- Rocky Linux 8 / 9
- AlmaLinux 8 / 9

### Minimum Requirements
- **CPU**: 1 Core
- **RAM**: 512 MB
- **Storage**: 1 GB free space
- **Network**: Public IP address
- **Domain**: A domain with NS record support

### Recommended Requirements
- **CPU**: 2+ Cores
- **RAM**: 1 GB+
- **Storage**: 5 GB+ free space
- **Network**: 100+ Mbps connection

---

## 🚀 Quick Installation

### One-Line Install Command

```bash
wget https://raw.githubusercontent.com/Samwelmushi/DNS-V2RY/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

### Or Manual Installation

```bash
# 1. Download the script
wget https://raw.githubusercontent.com/Samwelmushi/DNS-V2RY/main/install.sh

# 2. Make it executable
chmod +x install.sh

# 3. Run as root
sudo ./install.sh
```

---

## 📋 Installation Steps

### 1️⃣ Run the Script

```bash
sudo ./install.sh
```

### 2️⃣ Choose Option 1 - Full Installation

The script will automatically:
- Detect your operating system
- Install all required dependencies
- Install Go programming language
- Download and compile DNSTT server
- Install V2Ray core
- Configure firewall rules
- Optimize system settings

### 3️⃣ Configure Your Server

You'll be prompted for:

**Domain Configuration**:
```
Enter your domain (e.g., t.example.com): tunnel.yourdomain.com
```

**MTU Size** (for speed optimization):
```
Enter MTU size [default: 512]: 512
```
- **512**: Maximum compatibility (recommended)
- **800**: Better speed
- **1200**: High speed (may not work everywhere)

**V2Ray Protocol**:
```
1) VMess (Recommended for speed)
2) VLess (Latest protocol)
3) Trojan (High security)
```

### 4️⃣ DNS Configuration

After installation, add these records to your domain:

```
A Record:  ns.tunnel.yourdomain.com  →  YOUR_SERVER_IP
NS Record: tunnel.yourdomain.com     →  ns.tunnel.yourdomain.com
```

### 5️⃣ Copy Your Configuration

At the end of installation, you'll see all connection details. These are also saved to:
- `/etc/dnstt/full-config.txt`
- `/etc/dnstt/client-command.txt`
- `/etc/dnstt/server.pub`

---

## 🔧 Configuration Details

### Default Settings

| Setting | Value | Description |
|---------|-------|-------------|
| MTU Size | 512 bytes | Optimized for DNS tunneling |
| DNSTT Port | 5300 | UDP port for DNS tunnel |
| V2Ray Port | 1080 | Local SOCKS5 proxy |
| DNS Port | 53 | Standard DNS port |

### Speed Optimization Features

✅ **BBR Congestion Control** - Enabled by default  
✅ **TCP Fast Open** - Reduces latency  
✅ **Optimized Buffer Sizes** - 10240 bytes  
✅ **Connection Pooling** - Reuse connections  
✅ **Fast Handshake** - 4 seconds timeout  
✅ **Custom MTU Sizes** - Adjustable for your network

---

## 📱 Client Setup

### Step 1: Download DNSTT Client

**Windows/Linux/Mac**:
- Download from: [https://github.com/xjasonlyu/tun2socks/releases](https://github.com/xjasonlyu/tun2socks/releases)

**Android**:
- Use HTTP Injector, HTTP Custom, or similar apps

### Step 2: Save Public Key

Save the public key from installation output to `server.pub` file.

### Step 3: Run DNSTT Client

```bash
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey-file server.pub tunnel.yourdomain.com 127.0.0.1:7000
```

### Step 4: Configure V2Ray Client

Connect your V2Ray client to:
- **Address**: `127.0.0.1`
- **Port**: `7000`
- **Protocol**: VMess/VLess/Trojan (as configured)
- **UUID**: (from installation output)
- **AlterID**: `0`
- **Network**: `TCP`

---

## 🎮 Menu Options

### Main Menu Features

```
1)  Install DNSTT + V2Ray          - Full automated installation
2)  Check Service Status           - View running services
3)  Manage Services                - Start/Stop/Restart
4)  View Logs                      - Check service logs
5)  Change MTU Size                - Optimize speed
6)  Reconfigure DNSTT              - Change DNSTT settings
7)  Reconfigure V2Ray              - Change V2Ray settings
8)  Show Connection Info           - Display all details
9)  Backup Configuration           - Save your settings
10) Speed Test                     - Test network speed
11) Update Script                  - Get latest version
12) Uninstall                      - Remove everything
13) Exit                           - Close script
```

---

## 🔍 Troubleshooting

### Service Not Starting

```bash
# Check service status
sudo systemctl status dnstt-server
sudo systemctl status v2ray

# View logs
sudo journalctl -u dnstt-server -n 50
sudo journalctl -u v2ray -n 50
```

### DNS Not Resolving

1. Verify NS records are properly set
2. Wait 24-48 hours for DNS propagation
3. Test with: `nslookup tunnel.yourdomain.com`

### Low Speed

1. Try increasing MTU size (800 or 1200)
2. Check server bandwidth: `speedtest-cli`
3. Verify BBR is enabled: `sysctl net.ipv4.tcp_congestion_control`

### Connection Failed

1. Check firewall rules: `sudo iptables -L -n`
2. Verify ports are open: `sudo ss -tulnp | grep -E '53|5300|1080'`
3. Test DNS resolution: `dig @YOUR_SERVER_IP tunnel.yourdomain.com`

---

## 📊 Performance Optimization

### Recommended MTU Sizes by Network

| Network Type | Recommended MTU | Expected Speed |
|-------------|-----------------|----------------|
| Mobile 3G/4G | 512 | 1-3 Mbps |
| Public WiFi | 512-800 | 2-5 Mbps |
| Home Internet | 800-1200 | 3-10 Mbps |
| Data Center | 1200-1400 | 5-20 Mbps |

### System Optimization

The script automatically enables:
- **BBR Congestion Control**: Better throughput
- **TCP Fast Open**: Faster connections
- **Large Buffers**: Better data handling
- **Connection Reuse**: Reduced latency

---

## 🛡️ Security Features

- ✅ Encrypted DNS tunneling
- ✅ V2Ray encryption (VMess/VLess/Trojan)
- ✅ Unique UUID per installation
- ✅ Random key generation
- ✅ Secure protocol support
- ✅ No logging by default

---

## 📁 File Locations

```
/etc/dnstt/                       - DNSTT configuration directory
├── server.key                    - Private key
├── server.pub                    - Public key
├── dnstt-server.conf            - Server configuration
├── full-config.txt              - Complete configuration
└── client-command.txt           - Client connection command

/etc/v2ray/                      - V2Ray configuration directory
└── v2ray-config.txt            - V2Ray settings

/usr/local/etc/v2ray/           - V2Ray main directory
└── config.json                 - V2Ray configuration file

/var/log/v2ray/                 - V2Ray logs
├── access.log                  - Access logs
└── error.log                   - Error logs
```

---

## 🔄 Updating

### Update Script from GitHub

```bash
# Option 1: Use menu option 11
sudo ./install.sh
# Select option 11

# Option 2: Manual update
wget https://raw.githubusercontent.com/Samwelmushi/DNS-V2RY/main/install.sh -O install.sh
chmod +x install.sh
sudo ./install.sh
```

---

## 🗑️ Uninstallation

### Complete Removal

```bash
# Run the script
sudo ./install.sh

# Select option 12 - Uninstall
# Type 'yes' to confirm
```

This will remove:
- All DNSTT files and services
- All V2Ray files and services
- All configuration files
- All log files

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

- **DNSTT**: [https://www.bamsoftware.com/software/dnstt/](https://www.bamsoftware.com/software/dnstt/)
- **V2Ray**: [https://www.v2fly.org/](https://www.v2fly.org/)
- **V2Fly**: [https://github.com/v2fly](https://github.com/v2fly)

---

## 📞 Support

If you encounter any issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. View service logs using menu option 4
3. Open an issue on GitHub with detailed information
4. Include your OS version and error messages

---

## ⚠️ Disclaimer

This tool is provided for educational and legitimate privacy purposes only. Users are responsible for complying with their local laws and regulations. The author is not responsible for any misuse of this software.

---

## 📊 Statistics

![GitHub stars](https://img.shields.io/github/stars/Samwelmushi/DNS-V2RY?style=social)
![GitHub forks](https://img.shields.io/github/forks/Samwelmushi/DNS-V2RY?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/Samwelmushi/DNS-V2RY?style=social)

---

<div align="center">

### 👑 MADE BY THE KING 👑

**Star ⭐ this repository if you find it helpful!**

[Report Bug](https://github.com/Samwelmushi/DNS-V2RY/issues) · [Request Feature](https://github.com/Samwelmushi/DNS-V2RY/issues)

</div>
