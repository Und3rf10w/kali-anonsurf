#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./install_gui.sh"
    exit 1
fi

# Install Python GTK3 dependency
apt-get install -y python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-glib-2.0

# Install GUI script
mkdir -p /opt/anonsurf-gui
cp anonsurf_gui.py /opt/anonsurf-gui/
chmod +x /opt/anonsurf-gui/anonsurf_gui.py

# Create launcher in PATH
cat > /usr/local/bin/anonsurf-gui << 'EOF'
#!/bin/bash
python3 /opt/anonsurf-gui/anonsurf_gui.py
EOF
chmod +x /usr/local/bin/anonsurf-gui

# Install desktop entry
cp anonsurf-gui.desktop /usr/share/applications/
update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo ""
echo "[+] AnonSurf GUI installed!"
echo "    Run from terminal : anonsurf-gui"
echo "    Or find it in     : Applications > Network > AnonSurf GUI"
