#!/bin/bash
set -euo pipefail

LOGFILE="/root/setup_disk_setup.log"
exec > "$LOGFILE" 2>&1
echo "🔧 Starting disk setup..."

# Define mount points and required sizes in GB
declare -A MOUNTS=(
  ["/var"]="3"
  ["/var/log"]="3"
  ["/var/tmp"]="2"
  ["/tmp"]="2"
  ["/usr"]="3"
  ["/home"]="5"
)

# Define secure mount options
declare -A MOUNT_OPTIONS=(
  ["/home"]="nodev,nosuid"
  ["/var"]="nodev,nosuid"
  ["/tmp"]="nodev,nosuid,noexec"
  ["/var/tmp"]="nodev,nosuid,noexec"
  ["/var/log"]="nodev,nosuid"
  ["/usr"]="nodev"
)

GB=$((1024 * 1024 * 1024))

# Get root device basename (like xvda)
ROOT_DEV=$(findmnt -no SOURCE / | sed 's/[0-9]*$//' | xargs basename)
echo "🗂️ Root device detected as: $ROOT_DEV"

# Get available unmounted disks excluding root and loop devices
mapfile -t AVAILABLE_DISKS < <(
  lsblk -dn -o NAME,SIZE -b |
  awk -v root="$ROOT_DEV" '
    $1 !~ /^loop/ && $1 != root && $1 != "" { print "/dev/" $1, $2 }' |
  sort -k2,2n
)

declare -A DEVICE_MAP
declare -A USED_DISKS

# Assign disks to mount points
for dir in "${!MOUNTS[@]}"; do
  # Check if already on a separate disk (not on root)
  existing_dev=$(findmnt -nr -o SOURCE --target "$dir" 2>/dev/null || true)
  existing_dev_blk=$(lsblk -no PKNAME "$existing_dev" 2>/dev/null || true)

  if [[ -n "$existing_dev" && "$existing_dev_blk" != "$ROOT_DEV" ]]; then
    echo "ℹ️  Skipping $dir – already mounted on $existing_dev (not root)"
    continue
  fi

  required_size=$((MOUNTS[$dir] * GB))
  selected_dev=""

  for entry in "${AVAILABLE_DISKS[@]}"; do
    dev=$(echo "$entry" | awk '{print $1}')
    dev_size=$(echo "$entry" | awk '{print $2}')

    # Fix here: use :- to avoid unbound variable error under set -u
    if [[ "$dev_size" -ge "$required_size" && -z "${USED_DISKS[$dev]:-}" ]]; then
      selected_dev="$dev"
      USED_DISKS["$dev"]=1
      break
    fi
  done

  if [[ -n "$selected_dev" ]]; then
    DEVICE_MAP["$dir"]="$selected_dev"
  else
    echo "⚠️  No suitable disk found for $dir (needs ${MOUNTS[$dir]} GB)"
  fi
done

# Set up each selected mount point
for dir in "${!DEVICE_MAP[@]}"; do
  device="${DEVICE_MAP[$dir]}"
  label_name=$(basename "$dir" | tr -d '/')
  temp_mount="/mnt/$label_name"
  mount_opts="${MOUNT_OPTIONS[$dir]:-defaults}"

  echo "📁 Setting up $dir on $device (label: $label_name)"

  # Format disk if unformatted
  if ! blkid "$device" >/dev/null 2>&1; then
    echo "🌀 Formatting $device as ext4"
    mkfs.ext4 -L "$label_name" "$device"
  else
    echo "🔖 Relabeling existing filesystem as $label_name"
    e2label "$device" "$label_name"
  fi

  mkdir -p "$temp_mount"
  mount "$device" "$temp_mount"

  echo "📦 Copying data from $dir to $temp_mount"
  rsync -aHAX "$dir/" "$temp_mount/"

  umount "$temp_mount"
  mkdir -p "$dir"
  mount -o "$mount_opts" "$device" "$dir"

  grep -q "LABEL=$label_name" /etc/fstab || echo "LABEL=$label_name $dir ext4 $mount_opts 0 2" >> /etc/fstab
done

echo "✅ Disk setup complete."
echo "🔁 Reboot recommended to fully apply all persistent mounts."
