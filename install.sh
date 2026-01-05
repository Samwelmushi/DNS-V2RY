#!/bin/bash

# DNSTT + V2Ray Auto Installation Script
# GitHub: https://github.com/Samwelmushi/DNS-V2RY
# Description: High-speed DNSTT and V2Ray server setup with optimized MTU

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration paths
DNSTT_DIR="/etc/dnstt"
V2RAY_DIR="/etc/v2ray"
DNSTT_BIN="/usr/local/bin/dnstt-server"
V2RAY_BIN="/usr/local/bin/v2ray"
DNSTT_SERVICE="/etc/systemd/system/dnstt-server.service"
V2RAY_SERVICE="/etc/systemd/system/v2ray.service"

# Default MTU size (can be customized)
DEFAULT_MTU=512

# Banner with ASCII art
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║  ██████╗ ███╗   ██╗███████╗████████╗████████╗   ██╗   ██╗██████╗ ║"
    echo "║  ██╔══██╗████╗  ██║██╔════╝╚══██╔══╝╚══██╔══╝   ██║   ██║╚════██╗║"
    echo "║  ██║  ██║██╔██╗ ██║███████╗   ██║      ██║█████╗██║   ██║ █████╔╝║"
    echo "║  ██║  ██║██║╚██╗██║╚════██║   ██║      ██║╚════╝╚██╗ ██╔╝██╔═══╝ ║"
    echo "║  ██████╔╝██║ ╚████║███████║   ██║      ██║       ╚████╔╝ ███████╗║"
    echo "║  ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝      ╚═╝        ╚═══╝  ╚══════╝║"
    echo "║                                                                   ║"
    echo "║               ${YELLOW}High-Speed DNS Tunnel + V2Ray Server${CYAN}               ║"
    echo "║                                                                   ║"
    echo "║                     ${WHITE}MADE BY THE KING${CYAN}                            ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}${BOLD}✗ Error: This script must be run as root!${NC}"
        echo -e "${YELLOW}Please use: ${WHITE}sudo bash $0${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}✗ Error: Cannot detect OS${NC}"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            PKG_MANAGER="apt-get"
            PKG_UPDATE="apt-get update"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            PKG_MANAGER="yum"
            PKG_UPDATE="yum update -y"
            ;;
        *)
            echo -e "${RED}✗ Error: Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
}

# Progress indicator
show_progress() {
    local message=$1
    echo -ne "${YELLOW}⟳ $message...${NC}"
}

complete_progress() {
    echo -e "\r${GREEN}✓ $1 completed!${NC}"
}

# Install dependencies
install_dependencies() {
    show_progress "Installing system dependencies"
    $PKG_UPDATE > /dev/null 2>&1
    
    if [[ $PKG_MANAGER == "apt-get" ]]; then
        DEBIAN_FRONTEND=noninteractive $PKG_MANAGER install -y \
            wget curl tar gzip unzip openssl uuid-runtime jq \
            net-tools iptables iptables-persistent build-essential \
            ca-certificates > /dev/null 2>&1
    else
        $PKG_MANAGER install -y \
            wget curl tar gzip unzip openssl util-linux jq \
            net-tools iptables iptables-services gcc make \
            ca-certificates > /dev/null 2>&1
    fi
    
    complete_progress "Dependencies installation"
}

# Install Go
install_go() {
    show_progress "Installing Go programming language"
    
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        complete_progress "Go ${GO_VERSION} already installed"
        return 0
    fi
    
    GO_VERSION="1.21.5"
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        armv7l) GO_ARCH="armv6l" ;;
        *)
            echo -e "${RED}✗ Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac
    
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz -O /tmp/go.tar.gz
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    
    complete_progress "Go ${GO_VERSION} installation"
}

# Install DNSTT with custom MTU
install_dnstt() {
    show_progress "Installing DNSTT Server"
    
    mkdir -p $DNSTT_DIR
    
    cd /tmp
    wget -q https://www.bamsoftware.com/software/dnstt/dnstt-20220208.zip -O dnstt.zip
    unzip -q dnstt.zip
    cd dnstt-20220208/dnstt-server
    
    /usr/local/go/bin/go build -o dnstt-server
    mv dnstt-server $DNSTT_BIN
    chmod +x $DNSTT_BIN
    
    cd /tmp
    rm -rf dnstt.zip dnstt-20220208
    
    complete_progress "DNSTT Server installation"
}

# Generate DNSTT keys
generate_dnstt_keys() {
    show_progress "Generating DNSTT encryption keys"
    
    $DNSTT_BIN -gen-key -privkey-file $DNSTT_DIR/server.key -pubkey-file $DNSTT_DIR/server.pub
    
    if [[ -f $DNSTT_DIR/server.pub ]]; then
        complete_progress "DNSTT keys generation"
    else
        echo -e "${RED}✗ Error generating DNSTT keys${NC}"
        exit 1
    fi
}

# Configure DNSTT with custom MTU
configure_dnstt() {
    show_progress "Configuring DNSTT Server with MTU optimization"
    
    # Get server IP
    SERVER_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com)
    
    # Get domain
    echo ""
    read -p "$(echo -e ${CYAN}Enter your domain e.g., t.example.com${NC}): " DOMAIN
    
    # MTU Configuration
    echo ""
    echo -e "${YELLOW}MTU Size Configuration:${NC}"
    echo -e "${WHITE}Default MTU: 512 bytes (Optimized for DNS tunneling)${NC}"
    echo -e "${WHITE}For better speed, you can try: 800, 1200, or keep 512${NC}"
    read -p "$(echo -e ${CYAN}Enter MTU size [default: 512]${NC}): " MTU_SIZE
    MTU_SIZE=${MTU_SIZE:-$DEFAULT_MTU}
    
    UPSTREAM="127.0.0.1:1080"
    
    # Save configuration
    cat > $DNSTT_DIR/dnstt-server.conf <<EOF
DOMAIN=$DOMAIN
UPSTREAM=$UPSTREAM
SERVER_IP=$SERVER_IP
MTU_SIZE=$MTU_SIZE
EOF
    
    # Create systemd service with MTU parameter
    cat > $DNSTT_SERVICE <<EOF
[Unit]
Description=DNSTT Server - High Speed DNS Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=$DNSTT_BIN -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $MTU_SIZE $DOMAIN $UPSTREAM
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure firewall
    show_progress "Configuring firewall rules"
    
    iptables -F
    iptables -t nat -F
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    
    SSH_PORT=$(ss -tlnp | grep sshd | awk '{print $4}' | grep -oP ':\K\d+' | head -1)
    if [[ -z $SSH_PORT ]]; then
        SSH_PORT=22
    fi
    iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 5300 -j ACCEPT
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # Save iptables rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    elif command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/sysconfig/iptables 2>/dev/null
    fi
    
    systemctl daemon-reload
    systemctl enable dnstt-server > /dev/null 2>&1
    systemctl restart dnstt-server
    
    complete_progress "DNSTT Server configuration"
}

# Install V2Ray
install_v2ray() {
    show_progress "Installing V2Ray core"
    
    bash <(curl -sL https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) > /dev/null 2>&1
    
    complete_progress "V2Ray installation"
}

# Configure V2Ray with speed optimizations
configure_v2ray() {
    show_progress "Configuring V2Ray with speed optimizations"
    
    # Generate proper UUID using uuidgen (system command)
    if command -v uuidgen &> /dev/null; then
        UUID=$(uuidgen)
    else
        # Fallback UUID generation if uuidgen not available
        UUID=$(cat /proc/sys/kernel/random/uuid)
    fi
    
    # Save UUID to temp variable for later display
    export V2RAY_UUID_TEMP="$UUID"
    
    mkdir -p $V2RAY_DIR
    mkdir -p /var/log/v2ray
    
    # Protocol selection
    echo ""
    echo -e "${CYAN}${BOLD}Select V2Ray Protocol:${NC}"
    echo -e "${WHITE}1)${NC} VMess ${YELLOW}(Recommended for speed)${NC}"
    echo -e "${WHITE}2)${NC} VLess ${YELLOW}(Latest protocol)${NC}"
    echo -e "${WHITE}3)${NC} Trojan ${YELLOW}(High security)${NC}"
    read -p "$(echo -e ${CYAN}Enter choice [1-3]${NC}): " PROTOCOL_CHOICE
    
    case $PROTOCOL_CHOICE in
        2) PROTOCOL="vless" ;;
        3) 
            PROTOCOL="trojan"
            read -p "$(echo -e ${CYAN}Enter Trojan password${NC}): " TROJAN_PASSWORD
            export TROJAN_PASSWORD_TEMP="$TROJAN_PASSWORD"
            ;;
        *) PROTOCOL="vmess" ;;
    esac
    
    # Save protocol to temp variable for later display
    export V2RAY_PROTOCOL_TEMP="$PROTOCOL"
    
    # Create optimized V2Ray configuration
    if [[ $PROTOCOL == "trojan" ]]; then
        cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 1080,
    "listen": "127.0.0.1",
    "protocol": "trojan",
    "settings": {
      "clients": [{
        "password": "$TROJAN_PASSWORD",
        "level": 0
      }],
      "fallbacks": []
    },
    "streamSettings": {
      "network": "tcp",
      "tcpSettings": {
        "header": {
          "type": "none"
        }
      },
      "sockopt": {
        "tcpFastOpen": true,
        "tproxy": "off"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {},
    "streamSettings": {
      "sockopt": {
        "tcpFastOpen": true
      }
    }
  }],
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "bufferSize": 10240
      }
    }
  }
}
EOF
    else
        cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 1080,
    "listen": "127.0.0.1",
    "protocol": "$PROTOCOL",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "alterId": 0,
        "level": 0
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "tcpSettings": {
        "header": {
          "type": "none"
        }
      },
      "sockopt": {
        "tcpFastOpen": true,
        "tproxy": "off"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {},
    "streamSettings": {
      "sockopt": {
        "tcpFastOpen": true
      }
    }
  }],
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "bufferSize": 10240
      }
    },
    "system": {
      "statsInboundUplink": false,
      "statsInboundDownlink": false
    }
  }
}
EOF
    fi
    
# Save configuration info - REMOVED, no longer saving to files
    # Configuration will be displayed on screen only
    
    systemctl daemon-reload
    systemctl enable v2ray > /dev/null 2>&1
    systemctl restart v2ray
    
    complete_progress "V2Ray configuration"
}

# System optimization for speed
optimize_system() {
    show_progress "Optimizing system for maximum speed"
    
    # BBR Congestion Control
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf <<EOF

# TCP BBR Congestion Control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Network Performance Optimizations
fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
EOF
        sysctl -p > /dev/null 2>&1
    fi
    
    # File descriptor limits
    if ! grep -q "* soft nofile 51200" /etc/security/limits.conf; then
        cat >> /etc/security/limits.conf <<EOF

# Increase file descriptor limits
* soft nofile 51200
* hard nofile 51200
EOF
    fi
    
    # PAM limits
    if [[ ! -f /etc/pam.d/common-session ]] && [[ -f /etc/pam.d/system-auth ]]; then
        if ! grep -q "pam_limits.so" /etc/pam.d/system-auth; then
            echo "session required pam_limits.so" >> /etc/pam.d/system-auth
        fi
    elif [[ -f /etc/pam.d/common-session ]]; then
        if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
            echo "session required pam_limits.so" >> /etc/pam.d/common-session
        fi
    fi
    
    # Set ulimit
    ulimit -n 51200
    
    complete_progress "System optimization"
}

# Display connection information in copyable format
display_connection_info() {
    show_banner
    
    if [[ -f $DNSTT_DIR/dnstt-server.conf ]]; then
        . $DNSTT_DIR/dnstt-server.conf
    fi
    
    # Get V2Ray configuration directly from config file
    if [[ -f /usr/local/etc/v2ray/config.json ]]; then
        V2RAY_UUID=$(grep -oP '"id":\s*"\K[^"]+' /usr/local/etc/v2ray/config.json | head -1)
        V2RAY_PROTOCOL=$(grep -oP '"protocol":\s*"\K[^"]+' /usr/local/etc/v2ray/config.json | grep -E "vmess|vless|trojan" | head -1)
        if [[ $V2RAY_PROTOCOL == "trojan" ]]; then
            V2RAY_PASSWORD=$(grep -oP '"password":\s*"\K[^"]+' /usr/local/etc/v2ray/config.json | head -1)
        fi
    fi
    
    # Use temp variables if available (right after installation)
    if [[ -n "$V2RAY_UUID_TEMP" ]]; then
        V2RAY_UUID="$V2RAY_UUID_TEMP"
    fi
    if [[ -n "$V2RAY_PROTOCOL_TEMP" ]]; then
        V2RAY_PROTOCOL="$V2RAY_PROTOCOL_TEMP"
    fi
    if [[ -n "$TROJAN_PASSWORD_TEMP" ]]; then
        V2RAY_PASSWORD="$TROJAN_PASSWORD_TEMP"
    fi
    
    PUBKEY=$(cat $DNSTT_DIR/server.pub 2>/dev/null)
    
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                 INSTALLATION SUCCESSFUL!                      ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}                  SERVER INFORMATION${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Server IP:${NC}      ${GREEN}$SERVER_IP${NC}"
    echo -e "${WHITE}Domain:${NC}         ${GREEN}$DOMAIN${NC}"
    echo -e "${WHITE}MTU Size:${NC}       ${GREEN}$MTU_SIZE bytes${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}              DNS RECORDS (Add to your domain)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}A Record:${NC}  ${YELLOW}ns.$DOMAIN${NC} → ${YELLOW}$SERVER_IP${NC}"
    echo -e "${WHITE}NS Record:${NC} ${YELLOW}$DOMAIN${NC} → ${YELLOW}ns.$DOMAIN${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}              DNSTT PUBLIC KEY (Copy This)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$PUBKEY${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}              V2RAY CLIENT CONFIGURATION${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Address:${NC}    ${GREEN}127.0.0.1${NC}"
    echo -e "${WHITE}Port:${NC}       ${GREEN}7000${NC}"
    echo -e "${WHITE}Protocol:${NC}   ${GREEN}${V2RAY_PROTOCOL}${NC}"
    if [[ $V2RAY_PROTOCOL == "trojan" ]]; then
        echo -e "${WHITE}Password:${NC}   ${GREEN}${V2RAY_PASSWORD}${NC}"
    else
        echo -e "${WHITE}UUID:${NC}       ${GREEN}${V2RAY_UUID}${NC}"
        echo -e "${WHITE}AlterID:${NC}    ${GREEN}0${NC}"
    fi
    echo -e "${WHITE}Network:${NC}    ${GREEN}tcp${NC}"
    echo -e "${WHITE}Security:${NC}   ${GREEN}none${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         V2RAY CONFIG (Copy & Paste to V2Ray App)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Generate V2Ray client config based on protocol
    if [[ $V2RAY_PROTOCOL == "vmess" ]]; then
        # VMess link format
        VMESS_JSON="{\"v\":\"2\",\"ps\":\"DNSTT+V2Ray-${DOMAIN}\",\"add\":\"127.0.0.1\",\"port\":\"7000\",\"id\":\"${V2RAY_UUID}\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
        
        # Encode to base64 (use -w 0 to disable line wrapping)
        if base64 --help 2>&1 | grep -q "\-w"; then
            VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
        else
            # macOS doesn't support -w flag
            VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"
        fi
        
        echo -e "${WHITE}VMess Link (for V2RayNG, V2RayN, etc.):${NC}"
        echo -e "${GREEN}${VMESS_LINK}${NC}"
        echo ""
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}Or manually configure with these details:${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Remarks/Name:${NC} DNSTT+V2Ray-${DOMAIN}"
        echo -e "${CYAN}Address:${NC} 127.0.0.1"
        echo -e "${CYAN}Port:${NC} 7000"
        echo -e "${CYAN}UUID:${NC} ${V2RAY_UUID}"
        echo -e "${CYAN}AlterID:${NC} 0"
        echo -e "${CYAN}Network:${NC} tcp"
        echo -e "${CYAN}Security:${NC} none"
        
    elif [[ $V2RAY_PROTOCOL == "vless" ]]; then
        # VLess link format
        VLESS_LINK="vless://${V2RAY_UUID}@127.0.0.1:7000?type=tcp&security=none#DNSTT+V2Ray-${DOMAIN}"
        
        echo -e "${WHITE}VLess Link (for V2RayNG, V2RayN, etc.):${NC}"
        echo -e "${GREEN}${VLESS_LINK}${NC}"
        echo ""
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}Or manually configure with these details:${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Remarks/Name:${NC} DNSTT+V2Ray-${DOMAIN}"
        echo -e "${CYAN}Address:${NC} 127.0.0.1"
        echo -e "${CYAN}Port:${NC} 7000"
        echo -e "${CYAN}UUID:${NC} ${V2RAY_UUID}"
        echo -e "${CYAN}Network:${NC} tcp"
        echo -e "${CYAN}Security:${NC} none"
        
    elif [[ $V2RAY_PROTOCOL == "trojan" ]]; then
        # Trojan link format
        TROJAN_LINK="trojan://${V2RAY_PASSWORD}@127.0.0.1:7000?type=tcp&security=none#DNSTT+V2Ray-${DOMAIN}"
        
        echo -e "${WHITE}Trojan Link (for V2RayNG, V2RayN, etc.):${NC}"
        echo -e "${GREEN}${TROJAN_LINK}${NC}"
        echo ""
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}Or manually configure with these details:${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Remarks/Name:${NC} DNSTT+V2Ray-${DOMAIN}"
        echo -e "${CYAN}Address:${NC} 127.0.0.1"
        echo -e "${CYAN}Port:${NC} 7000"
        echo -e "${CYAN}Password:${NC} ${V2RAY_PASSWORD}"
        echo -e "${CYAN}Network:${NC} tcp"
        echo -e "${CYAN}Security:${NC} none"
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         📱 HOW TO USE WITH SLOW DNS V2RAY APP${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}This configuration works with apps like:${NC}"
    echo -e "  • ${CYAN}Slow DNS${NC}"
    echo -e "  • ${CYAN}HTTP Custom${NC} (V2ray SlowDNS Mod)"
    echo -e "  • ${CYAN}HTTP Injector${NC} (with SlowDNS plugin)"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}STEP-BY-STEP CONFIGURATION:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}1. Enable Custom DNS${NC}"
    echo -e "   Turn ON the ${CYAN}'Custom DNS'${NC} toggle"
    echo ""
    echo -e "${GREEN}${BOLD}2. Select V2Ray SlowDNS Mod${NC}"
    echo -e "   Tap: ${CYAN}'Custom V2raySlowDNS'${NC} or ${CYAN}'V2rayDNS Mod'${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}3. Fill in DNS Settings:${NC}"
    echo ""
    echo -e "   ${CYAN}DNS:${NC}"
    echo -e "   ${YELLOW}1.1.1.1${NC}  ${WHITE}(or use: 8.8.8.8, 169.255.187.58)${NC}"
    echo ""
    echo -e "   ${CYAN}Name Server:${NC}"
    echo -e "   ${YELLOW}${DOMAIN}${NC}"
    echo ""
    echo -e "   ${CYAN}Public Key:${NC}"
    echo -e "   ${YELLOW}${PUBKEY}${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}4. Paste V2Ray Configuration:${NC}"
    echo ""
    echo -e "   ${CYAN}V2ray, format(vmess://vless://++):${NC}"
    echo ""
    
    # Generate V2Ray client config based on protocol
    if [[ $V2RAY_PROTOCOL == "vmess" ]]; then
        # VMess link format
        VMESS_JSON="{\"v\":\"2\",\"ps\":\"DNSTT+V2Ray-${DOMAIN}\",\"add\":\"127.0.0.1\",\"port\":\"7000\",\"id\":\"${V2RAY_UUID}\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
        
        # Encode to base64 (use -w 0 to disable line wrapping)
        if base64 --help 2>&1 | grep -q "\-w"; then
            VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
        else
            # macOS doesn't support -w flag
            VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"
        fi
        
        echo -e "   ${YELLOW}${VMESS_LINK}${NC}"
        
    elif [[ $V2RAY_PROTOCOL == "vless" ]]; then
        # VLess link format
        VLESS_LINK="vless://${V2RAY_UUID}@127.0.0.1:7000?type=tcp&security=none#DNSTT+V2Ray-${DOMAIN}"
        
        echo -e "   ${YELLOW}${VLESS_LINK}${NC}"
        
    elif [[ $V2RAY_PROTOCOL == "trojan" ]]; then
        # Trojan link format
        TROJAN_LINK="trojan://${V2RAY_PASSWORD}@127.0.0.1:7000?type=tcp&security=none#DNSTT+V2Ray-${DOMAIN}"
        
        echo -e "   ${YELLOW}${TROJAN_LINK}${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}5. Click 'Start' Button${NC}"
    echo -e "   Wait 10-20 seconds for connection"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         📋 COPY & PASTE CONFIGURATION${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}DNS:${NC}"
    echo -e "${GREEN}1.1.1.1${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}Name Server:${NC}"
    echo -e "${GREEN}${DOMAIN}${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}Public Key:${NC}"
    echo -e "${GREEN}${PUBKEY}${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}V2Ray Link (vmess/vless/trojan):${NC}"
    
    if [[ $V2RAY_PROTOCOL == "vmess" ]]; then
        echo -e "${GREEN}${VMESS_LINK}${NC}"
    elif [[ $V2RAY_PROTOCOL == "vless" ]]; then
        echo -e "${GREEN}${VLESS_LINK}${NC}"
    elif [[ $V2RAY_PROTOCOL == "trojan" ]]; then
        echo -e "${GREEN}${TROJAN_LINK}${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         ⚙️ ALTERNATIVE DNS SERVERS (if connection fails)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Try these DNS servers if 1.1.1.1 doesn't work:${NC}"
    echo -e "  • ${GREEN}8.8.8.8${NC} ${WHITE}(Google DNS)${NC}"
    echo -e "  • ${GREEN}8.8.4.4${NC} ${WHITE}(Google DNS)${NC}"
    echo -e "  • ${GREEN}1.0.0.1${NC} ${WHITE}(Cloudflare DNS)${NC}"
    echo -e "  • ${GREEN}169.255.187.58${NC} ${WHITE}(Your Custom DNS)${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         🔧 MANUAL CONFIGURATION (Advanced)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}If the V2Ray link doesn't work, enter manually:${NC}"
    echo ""
    echo -e "${CYAN}Protocol:${NC} ${GREEN}${V2RAY_PROTOCOL}${NC}"
    echo -e "${CYAN}Address:${NC} ${GREEN}127.0.0.1${NC}"
    echo -e "${CYAN}Port:${NC} ${GREEN}7000${NC}"
    
    if [[ $V2RAY_PROTOCOL == "trojan" ]]; then
        echo -e "${CYAN}Password:${NC} ${GREEN}${V2RAY_PASSWORD}${NC}"
    else
        echo -e "${CYAN}UUID:${NC} ${GREEN}${V2RAY_UUID}${NC}"
        echo -e "${CYAN}AlterID:${NC} ${GREEN}0${NC}"
    fi
    
    echo -e "${CYAN}Network:${NC} ${GREEN}tcp${NC}"
    echo -e "${CYAN}Security:${NC} ${GREEN}none${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         ℹ️ DNS RECORDS (Add to your domain)${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Before connecting, add these records to your domain:${NC}"
    echo ""
    echo -e "${CYAN}A Record:${NC}"
    echo -e "  ${GREEN}ns.${DOMAIN}${NC} → ${GREEN}${SERVER_IP}${NC}"
    echo ""
    echo -e "${CYAN}NS Record:${NC}"
    echo -e "  ${GREEN}${DOMAIN}${NC} → ${GREEN}ns.${DOMAIN}${NC}"
    echo ""
    echo -e "${WHITE}⏰ Wait 24-48 hours for DNS propagation${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}         ⚠️ TROUBLESHOOTING${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}${BOLD}Connection Failed?${NC} ${WHITE}Try these solutions:${NC}"
    echo ""
    echo -e "  1. ${YELLOW}Check DNS records${NC} are correctly configured"
    echo -e "  2. ${YELLOW}Wait longer${NC} - DNS propagation can take up to 48 hours"
    echo -e "  3. ${YELLOW}Try different DNS${NC} - Use 8.8.8.8 or 169.255.187.58"
    echo -e "  4. ${YELLOW}Verify Public Key${NC} - Make sure it's copied correctly"
    echo -e "  5. ${YELLOW}Check Name Server${NC} - Must be: ${GREEN}${DOMAIN}${NC}"
    echo -e "  6. ${YELLOW}Restart services${NC} on server:"
    echo -e "     ${CYAN}systemctl restart dnstt-server v2ray${NC}"
    echo -e "  7. ${YELLOW}Check server logs${NC}:"
    echo -e "     ${CYAN}journalctl -u dnstt-server -f${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}${BOLD}⚠ CRITICAL: Copy all configuration above before pressing Enter!${NC}"
    echo -e "${RED}${BOLD}   This information will NOT be saved to any file.${NC}"
    echo -e "${RED}${BOLD}   You can see this info again by running: Menu Option 8${NC}"
    echo ""
    
    read -p "$(echo -e ${YELLOW}${BOLD}Press Enter after copying all information...${NC})"
}

# Full installation
full_install() {
    show_banner
    echo -e "${YELLOW}${BOLD}Starting DNSTT+V2Ray installation...${NC}"
    echo ""
    
    detect_os
    install_dependencies
    install_go
    install_dnstt
    generate_dnstt_keys
    configure_dnstt
    install_v2ray
    configure_v2ray
    optimize_system
    
    display_connection_info
}

# Check service status
check_status() {
    show_banner
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}                SERVICE STATUS${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}DNSTT Server:${NC}"
    if systemctl is-active --quiet dnstt-server; then
        echo -e "  Status: ${GREEN}● Running${NC}"
        echo -e "  Port: ${WHITE}$(ss -tulnp | grep dnstt | awk '{print $5}' | cut -d':' -f2 | head -1)${NC}"
        if [[ -f $DNSTT_DIR/dnstt-server.conf ]]; then
            . $DNSTT_DIR/dnstt-server.conf
            echo -e "  MTU: ${WHITE}$MTU_SIZE bytes${NC}"
        fi
    else
        echo -e "  Status: ${RED}● Stopped${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}${BOLD}V2Ray Server:${NC}"
    if systemctl is-active --quiet v2ray; then
        echo -e "  Status: ${GREEN}● Running${NC}"
        echo -e "  Port: ${WHITE}1080${NC}"
    else
        echo -e "  Status: ${RED}● Stopped${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}${BOLD}System Resources:${NC}"
    echo -e "  CPU Usage: ${WHITE}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%${NC}"
    echo -e "  Memory: ${WHITE}$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')${NC}"
    echo -e "  Disk: ${WHITE}$(df -h / | awk 'NR==2{print $5}')${NC}"
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# View logs menu
view_logs() {
    show_banner
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}                VIEW LOGS${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1) DNSTT Server Logs"
    echo "  2) V2Ray Access Logs"
    echo "  3) V2Ray Error Logs"
    echo "  4) System Logs"
    echo "  5) Back to Main Menu"
    echo ""
    read -p "$(echo -e ${CYAN}Enter your choice [1-5]${NC}): " LOG_CHOICE
    
    case $LOG_CHOICE in
        1)
            echo -e "${YELLOW}DNSTT Server Logs (last 100 lines):${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            journalctl -u dnstt-server -n 100 --no-pager
            ;;
        2)
            echo -e "${YELLOW}V2Ray Access Logs (last 100 lines):${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            if [[ -f /var/log/v2ray/access.log ]]; then
                tail -n 100 /var/log/v2ray/access.log
            else
                echo -e "${RED}No access log found${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}V2Ray Error Logs (last 100 lines):${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            if [[ -f /var/log/v2ray/error.log ]]; then
                tail -n 100 /var/log/v2ray/error.log
            else
                journalctl -u v2ray -n 100 --no-pager
            fi
            ;;
        4)
            echo -e "${YELLOW}System Logs (last 100 lines):${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            journalctl -n 100 --no-pager
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    echo ""
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# Manage services
manage_services() {
    show_banner
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}              MANAGE SERVICES${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "   1) Start DNSTT Server"
    echo "   2) Stop DNSTT Server"
    echo "   3) Restart DNSTT Server"
    echo "   4) Start V2Ray"
    echo "   5) Stop V2Ray"
    echo "   6) Restart V2Ray"
    echo "   7) Start All Services"
    echo "   8) Stop All Services"
    echo "   9) Restart All Services"
    echo "  10) Back to Main Menu"
    echo ""
    read -p "$(echo -e ${CYAN}Enter your choice [1-10]${NC}): " SERVICE_CHOICE
    
    case $SERVICE_CHOICE in
        1)
            systemctl start dnstt-server
            echo -e "${GREEN}✓ DNSTT Server started${NC}"
            ;;
        2)
            systemctl stop dnstt-server
            echo -e "${YELLOW}✓ DNSTT Server stopped${NC}"
            ;;
        3)
            systemctl restart dnstt-server
            echo -e "${GREEN}✓ DNSTT Server restarted${NC}"
            ;;
        4)
            systemctl start v2ray
            echo -e "${GREEN}✓ V2Ray started${NC}"
            ;;
        5)
            systemctl stop v2ray
            echo -e "${YELLOW}✓ V2Ray stopped${NC}"
            ;;
        6)
            systemctl restart v2ray
            echo -e "${GREEN}✓ V2Ray restarted${NC}"
            ;;
        7)
            systemctl start dnstt-server v2ray
            echo -e "${GREEN}✓ All services started${NC}"
            ;;
        8)
            systemctl stop dnstt-server v2ray
            echo -e "${YELLOW}✓ All services stopped${NC}"
            ;;
        9)
            systemctl restart dnstt-server v2ray
            echo -e "${GREEN}✓ All services restarted${NC}"
            ;;
        10)
            return
            ;;
        *)
            echo -e "${RED}✗ Invalid choice${NC}"
            ;;
    esac
    
    sleep 2
}

# Change MTU size
change_mtu() {
    show_banner
    echo -e "${YELLOW}${BOLD}Current MTU Configuration:${NC}"
    
    if [[ -f $DNSTT_DIR/dnstt-server.conf ]]; then
        . $DNSTT_DIR/dnstt-server.conf
        echo -e "${WHITE}Current MTU Size: ${GREEN}$MTU_SIZE bytes${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Recommended MTU sizes:${NC}"
    echo -e "${WHITE}• 512  - Maximum compatibility (default)${NC}"
    echo -e "${WHITE}• 800  - Better speed${NC}"
    echo -e "${WHITE}• 1200 - High speed (may not work everywhere)${NC}"
    echo -e "${WHITE}• 1400 - Maximum speed (rarely works)${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Enter new MTU size${NC}): " NEW_MTU
    
    if [[ ! $NEW_MTU =~ ^[0-9]+$ ]] || [[ $NEW_MTU -lt 256 ]] || [[ $NEW_MTU -gt 1500 ]]; then
        echo -e "${RED}✗ Invalid MTU size (must be 256-1500)${NC}"
        sleep 2
        return
    fi
    
    # Update configuration
    sed -i "s/MTU_SIZE=.*/MTU_SIZE=$NEW_MTU/" $DNSTT_DIR/dnstt-server.conf
    
    # Update service file
    sed -i "s/-mtu [0-9]*/-mtu $NEW_MTU/" $DNSTT_SERVICE
    
    # Restart service
    systemctl daemon-reload
    systemctl restart dnstt-server
    
    echo -e "${GREEN}✓ MTU size changed to $NEW_MTU bytes${NC}"
    sleep 2
}

# Reconfigure DNSTT
reconfigure_dnstt() {
    show_banner
    echo -e "${YELLOW}Reconfiguring DNSTT...${NC}"
    
    systemctl stop dnstt-server
    
    configure_dnstt
    
    echo -e "${GREEN}✓ DNSTT reconfigured successfully!${NC}"
    sleep 2
}

# Reconfigure V2Ray
reconfigure_v2ray() {
    show_banner
    echo -e "${YELLOW}Reconfiguring V2Ray...${NC}"
    
    systemctl stop v2ray
    
    configure_v2ray
    
    echo -e "${GREEN}✓ V2Ray reconfigured successfully!${NC}"
    sleep 2
}

# Show connection info
show_connection_info() {
    display_connection_info
}

# Backup configuration
backup_config() {
    show_banner
    echo -e "${YELLOW}Creating backup...${NC}"
    
    BACKUP_DIR="/root/dnstt-v2ray-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    if [[ -d $DNSTT_DIR ]]; then
        cp -r $DNSTT_DIR $BACKUP_DIR/
    fi
    
    if [[ -f /usr/local/etc/v2ray/config.json ]]; then
        mkdir -p $BACKUP_DIR/v2ray-etc
        cp /usr/local/etc/v2ray/config.json $BACKUP_DIR/v2ray-etc/
    fi
    
    tar -czf "$BACKUP_DIR.tar.gz" -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)
    rm -rf $BACKUP_DIR
    
    echo -e "${GREEN}✓ Backup created: $BACKUP_DIR.tar.gz${NC}"
    sleep 2
}

# Speed test
speed_test() {
    show_banner
    echo -e "${YELLOW}Running network speed test...${NC}"
    echo ""
    
    if ! command -v speedtest-cli &> /dev/null; then
        echo -e "${YELLOW}Installing speedtest-cli...${NC}"
        if [[ $PKG_MANAGER == "apt-get" ]]; then
            apt-get install -y speedtest-cli > /dev/null 2>&1
        else
            yum install -y speedtest-cli > /dev/null 2>&1
        fi
    fi
    
    speedtest-cli
    
    echo ""
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# Uninstall
uninstall_all() {
    show_banner
    echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}${BOLD}              UNINSTALL WARNING!${NC}"
    echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}This will remove:${NC}"
    echo -e "${WHITE}• All DNSTT installations${NC}"
    echo -e "${WHITE}• All V2Ray installations${NC}"
    echo -e "${WHITE}• All configuration files${NC}"
    echo -e "${WHITE}• All service files${NC}"
    echo ""
    read -p "$(echo -e ${RED}${BOLD}Type 'yes' to confirm uninstall${NC}): " CONFIRM
    
    if [[ $CONFIRM != "yes" ]]; then
        echo -e "${YELLOW}✓ Uninstall cancelled${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Uninstalling...${NC}"
    
    systemctl stop dnstt-server v2ray
    systemctl disable dnstt-server v2ray
    
    rm -f $DNSTT_SERVICE
    rm -f /etc/systemd/system/v2ray.service
    rm -f /etc/systemd/system/v2ray@.service
    
    rm -f $DNSTT_BIN
    rm -f /usr/local/bin/v2ray
    rm -f /usr/local/bin/v2ctl
    
    rm -rf $DNSTT_DIR
    rm -rf /usr/local/etc/v2ray
    rm -rf /usr/local/share/v2ray
    rm -rf /var/log/v2ray
    
    systemctl daemon-reload
    
    echo -e "${GREEN}✓ Uninstallation completed!${NC}"
    sleep 3
}

# Update script from GitHub
update_script() {
    show_banner
    echo -e "${YELLOW}Updating script from GitHub...${NC}"
    
    SCRIPT_URL="https://raw.githubusercontent.com/Samwelmushi/DNS-V2RY/main/install.sh"
    TEMP_SCRIPT="/tmp/install-new.sh"
    
    wget -q -O $TEMP_SCRIPT $SCRIPT_URL
    
    if [[ $? -eq 0 ]]; then
        chmod +x $TEMP_SCRIPT
        mv $TEMP_SCRIPT $0
        echo -e "${GREEN}✓ Script updated successfully! Restarting...${NC}"
        sleep 2
        exec $0
    else
        echo -e "${RED}✗ Failed to download update${NC}"
        sleep 2
    fi
}

# Main menu
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}${BOLD}                    MAIN MENU${NC}"
        echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${WHITE}1)${NC}  Install DNSTT + V2Ray ${YELLOW}(Full Installation)${NC}"
        echo -e "  ${WHITE}2)${NC}  Check Service Status"
        echo -e "  ${WHITE}3)${NC}  Manage Services ${YELLOW}(Start/Stop/Restart)${NC}"
        echo -e "  ${WHITE}4)${NC}  View Logs"
        echo -e "  ${WHITE}5)${NC}  Change MTU Size ${YELLOW}(Speed Optimization)${NC}"
        echo -e "  ${WHITE}6)${NC}  Reconfigure DNSTT"
        echo -e "  ${WHITE}7)${NC}  Reconfigure V2Ray"
        echo -e "  ${WHITE}8)${NC}  Show Connection Info ${YELLOW}(Copy & Paste)${NC}"
        echo -e "  ${WHITE}9)${NC}  Backup Configuration"
        echo -e " ${WHITE}10)${NC}  Speed Test"
        echo -e " ${WHITE}11)${NC}  Update Script from GitHub"
        echo -e " ${WHITE}12)${NC}  Uninstall"
        echo -e " ${WHITE}13)${NC}  Exit"
        echo ""
        echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p "$(echo -e ${GREEN}${BOLD}Enter your choice [1-13]${NC}): " MENU_CHOICE
        
        case $MENU_CHOICE in
            1)
                full_install
                ;;
            2)
                check_status
                ;;
            3)
                manage_services
                ;;
            4)
                view_logs
                ;;
            5)
                change_mtu
                ;;
            6)
                reconfigure_dnstt
                ;;
            7)
                reconfigure_v2ray
                ;;
            8)
                show_connection_info
                ;;
            9)
                backup_config
                ;;
            10)
                speed_test
                ;;
            11)
                update_script
                ;;
            12)
                uninstall_all
                ;;
            13)
                echo ""
                echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}${BOLD}║          Thank you for using DNSTT+V2Ray Script!             ║${NC}"
                echo -e "${GREEN}${BOLD}║                   MADE BY THE KING                            ║${NC}"
                echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}✗ Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start script
check_root
detect_os
main_menu
