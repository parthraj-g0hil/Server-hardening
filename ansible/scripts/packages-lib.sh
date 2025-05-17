#!/bin/bash

echo "=== Cleaning orphaned packages and services ==="

# 1. Remove unused packages
sudo apt-get autoremove -y

# 2. Remove residual config files
residuals=$(dpkg -l | awk '/^rc/ { print $2 }')
if [[ -n "$residuals" ]]; then
    sudo apt-get purge -y $residuals
else
    echo "No residual config files to purge."
fi

# 3. Clean package cache
sudo apt-get autoclean -y
sudo apt-get clean

# 4. Remove old Snap versions
if command -v snap &>/dev/null; then
    echo "Removing old Snap revisions..."
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
else
    echo "Snap not installed or not in PATH."
fi

echo "=== System cleanup complete ==="
