#!/bin/bash

# ============================================
#   Interactive Firewall Manager for Ubuntu
#   Uses UFW (Uncomplicated Firewall)
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR] This script must be run as root (use sudo).${NC}"
        exit 1
    fi
}

# Check UFW is installed
check_ufw() {
    if ! command -v ufw &>/dev/null; then
        echo -e "${YELLOW}UFW is not installed. Installing...${NC}"
        apt-get install -y ufw &>/dev/null
        echo -e "${GREEN}UFW installed successfully.${NC}"
    fi
}

# ── Banner ──────────────────────────────────────────────────────────────────
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║        Ubuntu Firewall Manager (UFW)         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    ufw_status=$(ufw status | head -1)
    if [[ "$ufw_status" == *"active"* ]]; then
        echo -e "  Firewall Status: ${GREEN}● ACTIVE${NC}"
    else
        echo -e "  Firewall Status: ${RED}● INACTIVE${NC}"
    fi
    echo ""
}

# ── Main Menu ────────────────────────────────────────────────────────────────
show_menu() {
    echo -e "${BOLD}  Main Menu${NC}"
    echo "  ─────────────────────────────────────"
    echo "  1) List all rules"
    echo "  2) Add a rule"
    echo "  3) Delete a rule"
    echo "  4) Edit an existing rule"
    echo "  5) Enable firewall"
    echo "  6) Disable firewall"
    echo "  7) Reset (delete all rules)"
    echo "  8) Allow common services (quick setup)"
    echo "  9) Show UFW status (verbose)"
    echo "  0) Exit"
    echo "  ─────────────────────────────────────"
    echo -n "  Choose an option: "
}

# ── 1. List Rules ─────────────────────────────────────────────────────────────
list_rules() {
    echo -e "\n${CYAN}${BOLD}  Current Firewall Rules:${NC}"
    echo "  ─────────────────────────────────────"
    ufw status numbered | sed 's/^/  /'
    echo ""
}

# ── 2. Add Rule ───────────────────────────────────────────────────────────────
add_rule() {
    echo -e "\n${CYAN}${BOLD}  Add Firewall Rule${NC}"
    echo "  ─────────────────────────────────────"
    echo "  Type:"
    echo "    1) Allow"
    echo "    2) Deny"
    echo -n "  Choose [1/2]: "
    read -r action_choice

    case $action_choice in
        1) action="allow" ;;
        2) action="deny"  ;;
        *) echo -e "${RED}  Invalid choice.${NC}"; return ;;
    esac

    echo ""
    echo "  What to apply the rule to?"
    echo "    1) Port"
    echo "    2) Port + Protocol (tcp/udp)"
    echo "    3) Port Range (e.g. 13000:13100/tcp)"
    echo "    4) IP Address"
    echo "    5) IP Address + Port"
    echo "    6) IP Address + Port Range"
    echo "    7) Service name (e.g. ssh, http)"
    echo -n "  Choose [1-7]: "
    read -r rule_type

    case $rule_type in
        1)
            echo -n "  Enter port number: "
            read -r port
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            ufw $action "$port"
            ;;
        2)
            echo -n "  Enter port number: "
            read -r port
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            ufw $action "$port/$proto"
            ;;
        3)
            echo -n "  Enter start port: "
            read -r port_start
            echo -n "  Enter end port: "
            read -r port_end
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port_start" =~ ^[0-9]+$ || ! "$port_end" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port range.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            [[ "$port_start" -ge "$port_end" ]] && echo -e "${RED}  Start port must be less than end port.${NC}" && return
            ufw $action "$port_start:$port_end/$proto"
            echo -e "${GREEN}  Range ${port_start}-${port_end}/${proto} applied!${NC}"
            ;;
        4)
            echo -n "  Enter IP address: "
            read -r ip
            ufw $action from "$ip"
            ;;
        5)
            echo -n "  Enter IP address: "
            read -r ip
            echo -n "  Enter port: "
            read -r port
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            ufw $action from "$ip" to any port "$port"
            ;;
        6)
            echo -n "  Enter IP address: "
            read -r ip
            echo -n "  Enter start port: "
            read -r port_start
            echo -n "  Enter end port: "
            read -r port_end
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port_start" =~ ^[0-9]+$ || ! "$port_end" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port range.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            [[ "$port_start" -ge "$port_end" ]] && echo -e "${RED}  Start port must be less than end port.${NC}" && return
            ufw $action from "$ip" to any port "$port_start:$port_end" proto "$proto"
            echo -e "${GREEN}  Range ${port_start}-${port_end}/${proto} from ${ip} applied!${NC}"
            ;;
        7)
            echo -n "  Enter service name (e.g. ssh, http, https): "
            read -r service
            ufw $action "$service"
            ;;
        *)
            echo -e "${RED}  Invalid choice.${NC}"
            return
            ;;
    esac

    echo -e "${GREEN}  Rule applied successfully!${NC}"
}

# ── 3. Delete Rule ────────────────────────────────────────────────────────────
delete_rule() {
    echo -e "\n${CYAN}${BOLD}  Delete Firewall Rule${NC}"
    echo "  ─────────────────────────────────────"
    ufw status numbered | sed 's/^/  /'
    echo ""
    echo -n "  Enter rule number to delete (or 0 to cancel): "
    read -r rule_num

    [[ "$rule_num" == "0" ]] && return
    [[ ! "$rule_num" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid number.${NC}" && return

    echo -n "  Are you sure you want to delete rule [$rule_num]? (y/N): "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        yes | ufw delete "$rule_num"
        echo -e "${GREEN}  Rule deleted.${NC}"
    else
        echo -e "${YELLOW}  Cancelled.${NC}"
    fi
}

# ── 4. Enable ─────────────────────────────────────────────────────────────────
enable_firewall() {
    echo -e "\n${YELLOW}  Enabling firewall...${NC}"
    yes | ufw enable
    echo -e "${GREEN}  Firewall is now ACTIVE.${NC}"
}

# ── 5. Disable ────────────────────────────────────────────────────────────────
disable_firewall() {
    echo -n "  Are you sure you want to DISABLE the firewall? (y/N): "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        ufw disable
        echo -e "${RED}  Firewall is now INACTIVE.${NC}"
    else
        echo -e "${YELLOW}  Cancelled.${NC}"
    fi
}

# ── 6. Reset ──────────────────────────────────────────────────────────────────
reset_firewall() {
    echo -e "${RED}  WARNING: This will delete ALL rules!${NC}"
    echo -n "  Type 'RESET' to confirm: "
    read -r confirm
    if [[ "$confirm" == "RESET" ]]; then
        yes | ufw reset
        echo -e "${GREEN}  Firewall rules have been reset.${NC}"
    else
        echo -e "${YELLOW}  Cancelled.${NC}"
    fi
}

# ── 7. Quick Setup ────────────────────────────────────────────────────────────
quick_setup() {
    echo -e "\n${CYAN}${BOLD}  Quick Setup - Allow Common Services${NC}"
    echo "  ─────────────────────────────────────"
    echo "  Select services to allow (space-separated numbers):"
    echo "    1) SSH (port 22)"
    echo "    2) HTTP (port 80)"
    echo "    3) HTTPS (port 443)"
    echo "    4) FTP (port 21)"
    echo "    5) MySQL (port 3306)"
    echo "    6) PostgreSQL (port 5432)"
    echo "    7) DNS (port 53)"
    echo "    8) SMTP (port 25)"
    echo -n "  Enter choices (e.g. 1 2 3): "
    read -r -a choices

    declare -A service_map=(
        [1]="22/tcp"
        [2]="80/tcp"
        [3]="443/tcp"
        [4]="21/tcp"
        [5]="3306/tcp"
        [6]="5432/tcp"
        [7]="53"
        [8]="25/tcp"
    )
    declare -A service_names=(
        [1]="SSH" [2]="HTTP" [3]="HTTPS" [4]="FTP"
        [5]="MySQL" [6]="PostgreSQL" [7]="DNS" [8]="SMTP"
    )

    for choice in "${choices[@]}"; do
        if [[ -n "${service_map[$choice]}" ]]; then
            ufw allow "${service_map[$choice]}"
            echo -e "${GREEN}  ✔ Allowed ${service_names[$choice]}${NC}"
        else
            echo -e "${RED}  ✘ Unknown option: $choice${NC}"
        fi
    done
}

# ── 8. Verbose Status ─────────────────────────────────────────────────────────
show_verbose_status() {
    echo -e "\n${CYAN}${BOLD}  UFW Verbose Status:${NC}"
    echo "  ─────────────────────────────────────"
    ufw status verbose | sed 's/^/  /'
    echo ""
}

# ── 4. Edit Rule ──────────────────────────────────────────────────────────────
edit_rule() {
    echo -e "\n${CYAN}${BOLD}  Edit Firewall Rule${NC}"
    echo "  ─────────────────────────────────────"
    echo -e "  ${YELLOW}How it works: select a rule to delete, then define its replacement.${NC}\n"

    ufw_rules=$(ufw status numbered)
    echo "$ufw_rules" | sed 's/^/  /'
    echo ""

    if ! echo "$ufw_rules" | grep -qP "^\[\s*\d+\]"; then
        echo -e "${RED}  No rules found to edit.${NC}"
        return
    fi

    echo -n "  Enter rule number to edit (or 0 to cancel): "
    read -r rule_num
    [[ "$rule_num" == "0" ]] && return
    [[ ! "$rule_num" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid number.${NC}" && return

    selected_rule=$(ufw status numbered | grep "^\[ *${rule_num}\]")
    if [[ -z "$selected_rule" ]]; then
        echo -e "${RED}  Rule number not found.${NC}"
        return
    fi

    echo -e "\n  ${YELLOW}Selected rule:${NC}"
    echo "  $selected_rule"
    echo ""

    echo -n "  Confirm editing this rule? (y/N): "
    read -r confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo -e "${YELLOW}  Cancelled.${NC}" && return

    echo -e "\n  ${YELLOW}Step 1: Deleting old rule...${NC}"
    yes | ufw delete "$rule_num" &>/dev/null
    echo -e "  ${GREEN}✔ Old rule removed.${NC}"

    echo -e "\n  ${CYAN}Step 2: Define the new rule${NC}"
    echo "  ─────────────────────────────────────"
    echo "  Action:"
    echo "    1) Allow"
    echo "    2) Deny"
    echo -n "  Choose [1/2]: "
    read -r action_choice
    case $action_choice in
        1) action="allow" ;;
        2) action="deny"  ;;
        *) echo -e "${RED}  Invalid choice. Rule was deleted — re-add manually.${NC}"; return ;;
    esac

    echo ""
    echo "  Rule type:"
    echo "    1) Port"
    echo "    2) Port + Protocol (tcp/udp)"
    echo "    3) Port Range (e.g. 13000-13100)"
    echo "    4) IP Address"
    echo "    5) IP Address + Port"
    echo "    6) IP Address + Port Range"
    echo "    7) Service name (e.g. ssh, http)"
    echo -n "  Choose [1-7]: "
    read -r rule_type

    case $rule_type in
        1)
            echo -n "  Enter port number: "
            read -r port
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            ufw $action "$port"
            ;;
        2)
            echo -n "  Enter port number: "
            read -r port
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            ufw $action "$port/$proto"
            ;;
        3)
            echo -n "  Enter start port: "
            read -r port_start
            echo -n "  Enter end port: "
            read -r port_end
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port_start" =~ ^[0-9]+$ || ! "$port_end" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port range.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            [[ "$port_start" -ge "$port_end" ]] && echo -e "${RED}  Start port must be less than end port.${NC}" && return
            ufw $action "$port_start:$port_end/$proto"
            ;;
        4)
            echo -n "  Enter IP address: "
            read -r ip
            ufw $action from "$ip"
            ;;
        5)
            echo -n "  Enter IP address: "
            read -r ip
            echo -n "  Enter port: "
            read -r port
            [[ ! "$port" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port.${NC}" && return
            ufw $action from "$ip" to any port "$port"
            ;;
        6)
            echo -n "  Enter IP address: "
            read -r ip
            echo -n "  Enter start port: "
            read -r port_start
            echo -n "  Enter end port: "
            read -r port_end
            echo -n "  Protocol (tcp/udp): "
            read -r proto
            [[ ! "$port_start" =~ ^[0-9]+$ || ! "$port_end" =~ ^[0-9]+$ ]] && echo -e "${RED}  Invalid port range.${NC}" && return
            [[ "$proto" != "tcp" && "$proto" != "udp" ]] && echo -e "${RED}  Invalid protocol.${NC}" && return
            [[ "$port_start" -ge "$port_end" ]] && echo -e "${RED}  Start port must be less than end port.${NC}" && return
            ufw $action from "$ip" to any port "$port_start:$port_end" proto "$proto"
            ;;
        7)
            echo -n "  Enter service name (e.g. ssh, http, https): "
            read -r service
            ufw $action "$service"
            ;;
        *)
            echo -e "${RED}  Invalid choice. Rule was deleted — re-add manually.${NC}"
            return
            ;;
    esac

    echo -e "\n  ${GREEN}✔ Rule updated successfully!${NC}"
    echo -e "\n  ${CYAN}Updated rules:${NC}"
    ufw status numbered | sed 's/^/  /'
}

# ── Main Loop ─────────────────────────────────────────────────────────────────
main() {
    check_root
    check_ufw

    while true; do
        show_banner
        show_menu
        read -r choice
        echo ""

        case $choice in
            1) list_rules ;;
            2) add_rule ;;
            3) delete_rule ;;
            4) edit_rule ;;
            5) enable_firewall ;;
            6) disable_firewall ;;
            7) reset_firewall ;;
            8) quick_setup ;;
            9) show_verbose_status ;;
            0)
                echo -e "${GREEN}  Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}  Invalid option. Please try again.${NC}"
                ;;
        esac

        echo ""
        echo -n "  Press [Enter] to continue..."
        read -r
    done
}

main
