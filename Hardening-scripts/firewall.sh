#!/bin/bash

echo "🛡️ Interactive UFW Firewall Configuration"

# Show currently listening ports and services
echo ""
echo "🔍 Currently open ports and listening services (via netstat):"
sudo netstat -tulpn | grep LISTEN || echo "No active listening ports found."
echo ""

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
  echo "📦 UFW not found, installing..."
  sudo apt update && sudo apt install -y ufw
fi

# Enable UFW if not already
if sudo ufw status | grep -q inactive; then
  echo "🔐 UFW is inactive, enabling..."
  sudo ufw --force enable
fi

# Function to show service choices
show_services() {
  echo "Select a service or enter a custom port:"
  echo "1) ssh (22)"
  echo "2) ftp (21)"
  echo "3) http (80)"
  echo "4) https (443)"
  echo "5) custom port"
}

while true; do
  echo ""
  read -rp "Do you want to add or remove a rule? (add/remove/exit): " task
  case "$task" in
    add)
      show_services
      read -rp "Enter choice (1-5): " service_choice
      case $service_choice in
        1) port=22; service="ssh" ;;
        2) port=21; service="ftp" ;;
        3) port=80; service="http" ;;
        4) port=443; service="https" ;;
        5)
          read -rp "Enter custom port number (1-65535): " port
          if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
            echo "❌ Invalid port number."
            continue
          fi
          service="custom"
          ;;
        *)
          echo "❌ Invalid choice."
          continue
          ;;
      esac

      read -rp "Allow or deny? (a/d): " action_choice
      case $action_choice in
        a) action="allow" ;;
        d) action="deny" ;;
        *) echo "❌ Invalid choice."; continue ;;
      esac

      read -rp "Enter IP or subnet (e.g. 192.168.1.100 or any): " ip
      if [[ "$ip" == "any" ]]; then
        cmd="sudo ufw $action $port/tcp"
      else
        cmd="sudo ufw $action from $ip to any port $port proto tcp"
      fi

      echo "🚀 Executing: $cmd"
      $cmd
      ;;
    
    remove)
      echo ""
      echo "📋 Current UFW Rules (numbered):"
      sudo ufw status numbered
      echo ""
      read -rp "Enter the rule number to delete: " delnum
      if [[ "$delnum" =~ ^[0-9]+$ ]]; then
        echo "🗑️ Deleting rule #$delnum..."
        sudo ufw delete "$delnum"
      else
        echo "❌ Invalid rule number."
      fi
      ;;
    
    exit)
      echo "✅ Exiting interactive firewall setup."
      break
      ;;
    
    *)
      echo "❌ Invalid option. Please enter add, remove, or exit."
      ;;
  esac

  echo ""
  echo "📊 Current UFW Status:"
  sudo ufw status verbose
done
