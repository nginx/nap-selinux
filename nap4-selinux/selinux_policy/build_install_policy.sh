#!/bin/bash

# Build and install SELinux policy for NGINX App Protect

set -e

# Check if we're root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Check if SELinux is enabled
echo "Checking SELinux status..."
if command -v getenforce >/dev/null 2>&1; then
    selinux_status=$(getenforce)
    echo "Current SELinux status: $selinux_status"
    
    if [ "$selinux_status" = "Disabled" ]; then
        echo "⚠ SELinux is disabled. Enabling SELinux..."
        
        # Backup the current SELinux config
        cp /etc/selinux/config /etc/selinux/config.backup.$(date +%Y%m%d_%H%M%S)
        echo "✓ Backed up current SELinux config"
        
        # Enable SELinux in permissive mode
        sed -i 's/^SELINUX=disabled/SELINUX=permissive/' /etc/selinux/config
        sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
        
        # Verify the change
        if grep -q "SELINUX=permissive" /etc/selinux/config; then
            echo "✓ SELinux config updated to permissive mode"
            echo "⚠ IMPORTANT: A system reboot is required for SELinux to be enabled."
            echo "After reboot, run this script again to install the policy."
            echo ""
            echo "Would you like to reboot now? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "Rebooting system..."
                reboot
            else
                echo "Please reboot manually and run this script again."
                exit 0
            fi
        else
            echo "✗ ERROR: Failed to update SELinux config"
            exit 1
        fi
    elif [ "$selinux_status" = "Enforcing" ]; then
        echo "⚠ SELinux is in enforcing mode. Setting to permissive mode for policy installation..."
        setenforce 0
        echo "✓ SELinux temporarily set to permissive mode"
        echo "Current SELinux status: $(getenforce)"
    else
        echo "✓ SELinux is already in permissive mode and can be managed"
    fi
else
    echo "✗ ERROR: SELinux tools not found. Installing SELinux packages..."
    dnf install -y policycoreutils selinux-policy selinux-policy-targeted
    echo "✓ SELinux packages installed. Please reboot and run this script again."
    exit 0
fi

#Install required packages for SELinux policy development and system utilities
echo "[INFO] Installing required packages..."
sudo dnf install -y \
    selinux-policy-devel \
    policycoreutils-devel \
    policycoreutils-python-utils \
    libselinux \
    libselinux-utils \
    python3-libselinux \
    python3-policycoreutils \
    make \
    m4 \
    gcc \
    audit \
    curl \
    systemd \
    vim || {
        echo "[FAIL] Failed to install required packages."
        exit 1
    }

# Get the start test time
thetime=$(date +%H:%M)

# Build policy
# NOTE: Ensure the following files are present in the current directory before running this script:
# - nginx-app-protect.fc (File contexts) 
# - nginx-app-protect.te (Type enforcement rules)
cd "$(dirname "$0")"
make -f /usr/share/selinux/devel/Makefile nginx-app-protect.pp

# Install policy
semodule -i nginx-app-protect.pp

# Check if the module is loaded
echo "Checking if the SELinux module is loaded..."
module_output=$(semodule -l | grep "nginx-app-protect")
if [ -n "$module_output" ]; then
    echo "✓ SELinux module 'nginx-app-protect' is successfully loaded"
    echo "Module details: $module_output"
else
    echo "✗ ERROR: SELinux module 'nginx-app-protect' is not loaded"
    exit 1
fi 

# Set SELinux to permissive mode (for testing)
setenforce 0
echo "Current SELinux status:"
getenforce

# NGINX restart and status check
echo "[INFO] Final NGINX restart..."
sudo systemctl restart nginx || { echo "[FAIL] Final NGINX restart failed"; exit 1; }

echo "[INFO] Checking NGINX status..."
sudo systemctl is-active --quiet nginx && echo "[INFO] NGINX is running" || { echo "[FAIL] NGINX is not running"; exit 1; }

# Set SELinux to enforcing mode
echo "Setting SELinux to enforcing mode..."
setenforce 1

# Verify SELinux is in enforcing mode
echo "Verifying SELinux mode..."
current_mode=$(getenforce)
if [ "$current_mode" = "Enforcing" ]; then
    echo "✓ SELinux is now in enforcing mode"
else
    echo "✗ WARNING: SELinux is not in enforcing mode. Current mode: $current_mode"
    exit 1
fi

# Final NGINX restart and status check
echo "[INFO] Final NGINX restart..."
sudo systemctl restart nginx || { echo "[FAIL] Final NGINX restart failed"; exit 1; }

echo "[INFO] Checking NGINX status..."
sudo systemctl is-active --quiet nginx && echo "[INFO] NGINX is running" || { echo "[FAIL] NGINX is not running"; exit 1; }


# Final status check
echo ""
echo "=== Final Status ==="
echo "SELinux Status: $(getenforce)"
echo "Loaded nginx-app-protect module:"
semodule -l | grep "nginx-app-protect" || echo "Module not found"
echo ""
echo "SELinux policy installation completed successfully!"
