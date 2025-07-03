#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Optional: Enable debugging
# set -x

# Paths
MAKEFILE="/usr/share/selinux/devel/Makefile"
MODULE_NAME="nginx-app-protect"
MODULE_FILE="${MODULE_NAME}.pp"

echo "Cleaning previous build..."
if ! sudo make -f "$MAKEFILE" clean; then
    echo "Failed to clean previous SELinux module build." >&2
    exit 1
fi

echo "Building SELinux module..."
if ! sudo make -f "$MAKEFILE" "$MODULE_FILE"; then
    echo "Failed to build the SELinux module ($MODULE_FILE)." >&2
    exit 1
fi

echo "Installing SELinux module..."
if ! sudo semodule -i "$MODULE_FILE"; then
    echo "Failed to install the SELinux module ($MODULE_FILE)." >&2
    exit 1
fi

echo "Verifying installed SELinux module..."
if ! sudo semodule -lfull | grep -q "$MODULE_NAME"; then
    echo "SELinux module '$MODULE_NAME' not found after install!" >&2
    exit 1
fi

echo "SELinux module '$MODULE_NAME' installed and verified successfully."
