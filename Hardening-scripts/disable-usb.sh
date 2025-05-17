#!/bin/bash
set -e

echo "🔒 Disabling USB storage devices..."

# Create blacklist file for usb-storage
BLACKLIST_FILE="/etc/modprobe.d/blacklist-usbstorage.conf"

if [[ ! -f "$BLACKLIST_FILE" ]]; then
    echo "blacklist usb-storage" | sudo tee "$BLACKLIST_FILE"
    echo "USB storage module blacklisted."
else
    echo "Blacklist file already exists."
fi

# Update initramfs so blacklist is applied at boot
sudo update-initramfs -u

echo "🔄 Please reboot your system to apply changes."
