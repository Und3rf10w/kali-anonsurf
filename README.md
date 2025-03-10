# **Kali-Anonstealth**

**Kali-Anonstealth** is a port of ParrotSec's Anonsurf and Pandora designed to work seamlessly with Kali Linux. It enables system-wide anonymization through TOR and offers tools for secure and private usage.

*This repo contains the sources of both the anonsurf and pandora packages from ParrotSec combined into one.*

*This repo can be compiled into a deb package to correctly install it on a Kali system.*

---

## **Features**

### **Anonsurf**
- **TOR Proxy**: Anonymizes the entire system using TOR.
- **System-Wide Configuration**: Redirects traffic through iptables.
- **I2P Integration**: Start and stop I2P services.
- **Interactive Mode**: User-friendly terminal interface for all options.
- **IP Management**: Change IP address or view your current public IP.
- **IPv6 Support**: Enable or disable IPv6 for compatibility.
- **Kill Switch**: Blocks all traffic to maintain privacy when required.
- **OpenVpn**: Integrates OpenVPN functionality to enhance anonymization.
- **MACspoof**:Allows you to spoof your MAC (Media Access Control) address.
### **Pandora**
- **RAM Overwrite**: Clears RAM automatically on shutdown.
- **Manual Cache Clearing**: Ensures privacy by purging cache on demand.

---

## **Getting Started**

### **Clone the Repository**
```bash
git clone https://github.com/Und3rf10w/kali-anonsurf.git
cd kali-anonstealth
chmod +x *
./installer.sh
```
---

*NOTE*: This may work with any debian/ubuntu system, but this has only been tested to work on a kali-rolling amd64 system

---

## **Usage**

### **AnonSurf**
Anonsurf provides a variety of commands to manage anonymity and privacy:
```bash
anonsurf {start|stop|restart|change|changeip|status|myip|interactive|starti2p|stopi2p}
```

#### **Commands**
- **`start`**: Start system-wide anonymous tunneling under TOR.
- **`stop`**: Reset iptables and return to clear navigation.
- **`restart`**: Combines "stop" and "start" options for a fresh restart.
- **`change`**: Reload the TOR daemon to change the TOR identity.
- **`changeip`**: Restart the TOR service to change the public IP address.
- **`status`**: Check if Anonsurf is functioning properly.
- **`myip`**: Display your current public IP address.
- **`interactive`**: Launch an interactive menu with all available options.

#### **I2P Integration**
- **`starti2p`**: Start I2P services.
- **`stopi2p`**: Stop I2P services.

**Examples:**
```bash
anonsurf start
anonsurf changeip
anonsurf interactive
```

---

### **Pandora**
Clear RAM and ensure no cache or sensitive data remains:
```bash
pandora bomb
```

**Note**: This will clear all system caches, including active SSH sessions.

---

### **Other Functionalities**

#### **IPv6 Management**
- **Disable IPv6**: Prevents IPv6 traffic for enhanced anonymity.
```bash
anonsurf disable_ipv6
```

- **Enable IPv6**: Re-enable IPv6 traffic if necessary.
```bash
anonsurf enable_ipv6
```

#### **Kill Switch**
Activate a kill switch to block all network traffic:
```bash
anonsurf kill_switch
```

---

## **Highlights**
- **Private Internet Access DNS**: Uses DNS servers for enhanced privacy.
- **Logging**: Activities are logged in `/var/log/anonsurf.log` for analysis.
- **Compatibility**: Tested on Kali Rolling (amd64).
- **Interactive Interface**: Provides easy-to-navigate options in the terminal.

---

## **License**
This project is distributed under the **GNU General Public License v3.0**. See the `LICENSE` file for more details.

---
