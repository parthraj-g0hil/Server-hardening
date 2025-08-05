import os
import requests

GITHUB_RAW_BASE = "https://raw.githubusercontent.com/parthraj-g0hil/Server-hardening/52673959eccc6204c02c5c16a63a97459501dae1/Hardening-scripts"

scripts = [
    "apparmor.sh",
    "disable-usb.sh",
    "filesystem.py",
    "firewall.sh",
    "grub.sh",
    "package-lock.sh",
    "packages-lib.sh",
    "password-policy.sh",
    "ulimit.sh",
    "unwanted-users.sh",
    "version-hardening.sh"
]

def download_script(script_name, save_dir="./"):
    url = f"{GITHUB_RAW_BASE}/{script_name}"
    response = requests.get(url)
    if response.status_code == 200:
        file_path = os.path.join(save_dir, script_name)
        with open(file_path, "w") as f:
            f.write(response.text)
        print(f"✔ Downloaded: {script_name}")
    else:
        print(f"❌ Failed to download: {script_name} (Status {response.status_code})")

def show_menu():
    print("========= Server Hardening Menu =========\n")
    for idx, name in enumerate(scripts, start=1):
        print(f"{idx}. {name}")
    print()

def main():
    show_menu()
    selection = input("Select script numbers (comma separated): ").strip()
    try:
        choices = [int(x.strip()) for x in selection.split(",")]
    except ValueError:
        print("Invalid input. Please enter numbers only.")
        return

    for idx in choices:
        if 1 <= idx <= len(scripts):
            download_script(scripts[idx - 1])
        else:
            print(f"Invalid selection: {idx}")

if __name__ == "__main__":
    main()
