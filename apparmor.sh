#!/bin/bash
set -e

echo -e "\n🔐 AppArmor Hardening Script (Ubuntu)"
echo "--------------------------------------"

# Ensure AppArmor is installed
if ! command -v aa-status &>/dev/null; then
    echo "📦 Installing AppArmor and utilities..."
    apt update && apt install -y apparmor apparmor-utils
else
    echo "✅ AppArmor is already installed."
fi

# Enable and start AppArmor
echo -e "\n🚀 Enabling AppArmor service..."
systemctl enable apparmor
systemctl start apparmor

# Interactive menu
while true; do
    echo -e "\n🔧 What do you want to do?"
    echo "1) List Enforced Profiles"
    echo "2) List Profiles in Complain Mode"
    echo "3) Set Profile to Enforce Mode"
    echo "4) Set Profile to Complain Mode"
    echo "5) Disable Profile"
    echo "6) Exit"

    read -rp "👉 Enter choice [1-6]: " choice
    case "$choice" in
        1)
            echo -e "\n🔒 Enforced Profiles:"
            aa-status | awk '/profiles are in enforce mode|enforce mode/'
            aa-status | awk '/processes are in enforce mode/,/processes are in complain mode/' | sed '/processes are in complain mode/,$d'
            ;;
        2)
            echo -e "\n📢 Complain Mode Profiles:"
            aa-status | awk '/profiles are in complain mode|complain mode/'
            aa-status | awk '/processes are in complain mode/,/processes are in prompt mode/' | sed '/processes are in prompt mode/,$d'
            ;;
        3)
            read -rp "🔧 Enter profile path (e.g., /etc/apparmor.d/usr.sbin.nginx): " prof
            [[ -f "$prof" ]] && sudo aa-enforce "$prof" && echo "✅ Set to enforce." || echo "❌ Profile not found."
            ;;
        4)
            read -rp "📢 Enter profile path: " prof
            [[ -f "$prof" ]] && sudo aa-complain "$prof" && echo "✅ Set to complain." || echo "❌ Profile not found."
            ;;
        5)
            read -rp "🛑 Enter profile path: " prof
            [[ -f "$prof" ]] && sudo aa-disable "$prof" && echo "⛔ Profile disabled." || echo "❌ Profile not found."
            ;;
        6)
            echo "👋 Exiting."
            break
            ;;
        *)
            echo "❗ Invalid option. Try again."
            ;;
    esac
done
