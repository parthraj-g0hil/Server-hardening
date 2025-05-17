#!/bin/bash
set -e

echo "🔐 Secure GRUB with password for edit access only (no boot-time lock)"

# Set GRUB username and password
grub_user="admin"
grub_password="parthraj@123"

# Generate GRUB password hash using echo and piping
grub_hash=$(echo -e "${grub_password}\n${grub_password}" | grub-mkpasswd-pbkdf2 | grep "PBKDF2 hash" | awk '{print $NF}')
echo "✅ GRUB password hash generated."

# Backup 40_custom before modifying
CUSTOM_FILE="/etc/grub.d/40_custom"
BACKUP_FILE="${CUSTOM_FILE}.bak.$(date +%F-%T)"
cp "$CUSTOM_FILE" "$BACKUP_FILE"
echo "🧾 Backup of 40_custom created at: $BACKUP_FILE"

# Append GRUB superuser and password hash if not already present
if ! grep -q "password_pbkdf2 $grub_user" "$CUSTOM_FILE"; then
    cat <<EOF >> "$CUSTOM_FILE"

# GRUB password protection
set superuser="$grub_user"
password_pbkdf2 $grub_user $grub_hash
EOF
    echo "✅ Added GRUB superuser configuration."
else
    echo "⚠️ GRUB superuser config already exists. Please verify $CUSTOM_FILE."
fi

# Backup /etc/default/grub before modifying
DEFAULTS_FILE="/etc/default/grub"
BACKUP_DEFAULTS="${DEFAULTS_FILE}.bak.$(date +%F-%T)"
cp "$DEFAULTS_FILE" "$BACKUP_DEFAULTS"
echo "🧾 Backup of grub defaults created at: $BACKUP_DEFAULTS"

# Update or add required GRUB options safely
if grep -q "^GRUB_TIMEOUT_STYLE=" "$DEFAULTS_FILE"; then
    sed -i "s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/" "$DEFAULTS_FILE"
else
    echo "GRUB_TIMEOUT_STYLE=menu" >> "$DEFAULTS_FILE"
fi

if grep -q "^GRUB_ENABLE_CRYPTODISK=" "$DEFAULTS_FILE"; then
    sed -i "s/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/" "$DEFAULTS_FILE"
else
    echo "GRUB_ENABLE_CRYPTODISK=y" >> "$DEFAULTS_FILE"
fi

echo "🔁 Updating GRUB configuration..."
update-grub

echo "✅ GRUB password protection enabled for user '$grub_user'."
echo "🚀 Normal boots won't ask for a password, but editing boot entries or accessing GRUB CLI will."
