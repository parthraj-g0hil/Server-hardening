#!/bin/bash

# List of crucial packages to hold
crucial_packages=(
  "linux-image-generic"
  "openssh-server"
  "apache2"
  "nginx"
  "mysql-server"
  "ufw"
  "python3"
  "docker.io"
)

for pkg in "${crucial_packages[@]}"; do
  # Check if package is installed
  if dpkg -s "$pkg" &>/dev/null; then
    echo "Holding installed package: $pkg"
    sudo apt-mark hold "$pkg"
  else
    echo "Package $pkg is not installed. Skipping hold."
  fi
done

echo "Currently held packages:"
apt-mark showhold
