#!/bin/bash

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

echo "Setting fs.file-max to 65535 in /etc/sysctl.conf..."
grep -q "^fs.file-max" /etc/sysctl.conf && \
  sed -i 's/^fs.file-max.*/fs.file-max = 65535/' /etc/sysctl.conf || \
  echo "fs.file-max = 65535" >> /etc/sysctl.conf

echo "Applying sysctl changes..."
sysctl -p

echo "Updating /etc/security/limits.conf..."
cat <<EOF >> /etc/security/limits.conf

# Added by ulimt.sh
* soft     nproc          65535
* hard     nproc          65535
* soft     nofile         65535
* hard     nofile         65535
root soft     nproc          65535
root hard     nproc          65535
root soft     nofile         65535
root hard     nofile         65535
EOF

echo "Ensuring 'pam_limits.so' is present in /etc/pam.d/common-session..."
if ! grep -q "^session required pam_limits.so" /etc/pam.d/common-session; then
  echo "session required pam_limits.so" >> /etc/pam.d/common-session
fi

echo "All limits have been set successfully."
