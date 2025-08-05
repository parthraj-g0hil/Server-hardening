import subprocess
import os
import uuid

# Get UUID of a partition
def get_uuid(dev):
    try:
        return subprocess.check_output(['blkid', '-s', 'UUID', '-o', 'value', f'/dev/{dev}']).decode().strip()
    except subprocess.CalledProcessError:
        return None

# Run command and print it
def run(cmd):
    print(f">>> {cmd}")
    subprocess.run(cmd, shell=True, check=True)

# Display current filesystem info
def show_disks():
    print("Current Disk Usage:\n")
    run("df -h")
    print("\nBlock Devices:\n")
    run("lsblk")

# Handle swap partition
def configure_swap(partition):
    run(f"mkswap /dev/{partition}")
    run(f"swapon /dev/{partition}")
    uuid_val = get_uuid(partition)
    if uuid_val:
        fstab_entry = f"UUID={uuid_val} none swap sw,nofail 0 2\n"
        with open('/etc/fstab', 'a') as f:
            f.write(fstab_entry)
    run("sysctl vm.swappiness=30")
    print("Swap setup complete.\n")

# Handle data partitions (/tmp, /var, etc.)
def configure_partition(partition, mount_point, fs_type, fstab_opts):
    target_dir = f"/xyz-{mount_point.strip('/')}"
    os.makedirs(target_dir, exist_ok=True)
    
    # Create FS
    run(f"mkfs.{fs_type} /dev/{partition}")
    
    # Mount new FS temporarily
    run(f"mount /dev/{partition} {target_dir}")
    
    # Rsync data
    run(f"rsync -avrz /{mount_point.strip('/')}/* {target_dir}/")
    
    # Remount to actual mount point
    run(f"umount {target_dir}")
    run(f"mount /dev/{partition} /{mount_point.strip('/')}")
    
    # Add to fstab
    uuid_val = get_uuid(partition)
    if uuid_val:
        fstab_entry = f"UUID={uuid_val} /{mount_point.strip('/')} {fs_type} {fstab_opts} 1 2\n"
        with open('/etc/fstab', 'a') as f:
            f.write(fstab_entry)

    print(f"{mount_point} successfully configured.")

# Mount options mapping
fstab_options = {
    "/var/tmp": "nodev,nosuid,noexec",
    "/usr": "nodev",
    "/home": "nodev,nosuid",
    "/var": "nodev,nosuid",
    "/var/log": "nodev,nosuid",
    "/tmp": "defaults,nosuid,nodev,noexec",
    "/app": "nodev,nosuid,noexec",
    "swap": "sw,nofail",
    "/dev/shm": "defaults,nodev,nosuid,noexec"
}

# Main script flow
def main():
    while True:
        show_disks()

        partition = input("Enter the disk partition (e.g., xvdd,xvdf): ").strip()
        mount_point = input("Enter the mount point (/tmp, /var, /var/log, /home, swap): ").strip()
        fs_type = input("Enter filesystem type (xfs/ext4/swap): ").strip().lower()

        if mount_point == "swap" or fs_type == "swap":
            configure_swap(partition)
        else:
            opts = fstab_options.get(mount_point, "defaults")
            configure_partition(partition, mount_point, fs_type, opts)

        show_disks()
        more = input("Do you want to configure another partition? (y/n): ").strip().lower()
        if more != 'y':
            break

if __name__ == "__main__":
    main()
