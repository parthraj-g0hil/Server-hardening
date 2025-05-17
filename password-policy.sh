#!/bin/bash
set -e

# Enable logging only if ENABLE_LOGGING=1 is set in environment
if [ "$ENABLE_LOGGING" == "1" ]; then
    exec > /root/enforce_strong_password.log 2>&1
fi

echo "INFO: Starting password policy enforcement..."

# === Wait for apt locks to be released ===
echo "INFO: Waiting for apt locks to be released..."
timeout=60
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
        echo "ERROR: Timeout waiting for apt lock"
        exit 1
    fi
    echo "INFO: Waiting for apt locks... $timeout seconds left"
    sleep 1
    ((timeout--))
done

# === Check and Install Required Packages ===
REQUIRED_PACKAGES=(libpam-pwquality libpam-modules)
MISSING_PACKAGES=()

echo "INFO: Checking for required packages..."
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    dpkg -s "$pkg" &> /dev/null || MISSING_PACKAGES+=("$pkg")
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "INFO: Missing packages found: ${MISSING_PACKAGES[*]}"
    echo "INFO: Updating APT cache and installing missing packages..."
    apt install -y "${MISSING_PACKAGES[@]}"
else
    echo "INFO: All required packages are already installed."
fi

# === PAM File Path ===
PAM_FILE="/etc/pam.d/common-password"

# === Password Quality Configuration ===
PWQUALITY_ATTRS="retry=3 minlen=12 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=4 reject_username enforce_for_root"

# === Update or Add pam_pwquality.so line ===
if grep -q "pam_pwquality.so" "$PAM_FILE"; then
    echo "INFO: Updating pam_pwquality.so configuration..."
    sed -i -E "s|^([[:space:]]*password[[:space:]]+requisite[[:space:]]+pam_pwquality\.so).*|\1 $PWQUALITY_ATTRS|" "$PAM_FILE"
else
    echo "ERROR: pam_pwquality.so line not found. Please ensure it's present before running this script."
    exit 1
fi

# === Update or Add pam_pwhistory.so line ===
if grep -q "pam_pwhistory.so" "$PAM_FILE"; then
    echo "INFO: Updating existing pam_pwhistory.so line..."
    sed -i -E "s|^([[:space:]]*password[[:space:]]+required[[:space:]]+pam_pwhistory\.so).*|\1 remember=5 use_authtok enforce_for_root|" "$PAM_FILE"
else
    echo "INFO: Adding pam_pwhistory.so before pam_unix.so..."
    sed -i "/pam_unix.so/i password        required                        pam_pwhistory.so remember=5 use_authtok enforce_for_root" "$PAM_FILE"
fi

# === Confirm Final Config ===
echo "INFO: Final pam_pwquality line:"
grep "pam_pwquality.so" "$PAM_FILE"
echo "INFO: Final pam_pwhistory line:"
grep "pam_pwhistory.so" "$PAM_FILE"

echo "INFO: Password policies successfully enforced."
