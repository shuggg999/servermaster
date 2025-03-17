#!/bin/bash

# System Information Query Module
# For ServerMaster script

# Set locale to ensure proper character display
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Check if colors are passed from the main script
if [ -z "$GREEN" ]; then
    GREEN='\033[0;32m'
    BRIGHT_GREEN='\033[1;32m'
    CYAN='\033[0;36m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    WHITE='\033[1;37m'
    GRAY='\033[0;37m'
    NC='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    HIDDEN='\033[8m'
fi

# Define box drawing characters
BOX_TL="+"
BOX_TR="+"
BOX_BL="+"
BOX_BR="+"
BOX_H="-"
BOX_V="|"
BOX_VR="+"
BOX_VL="+"
BOX_HU="+"
BOX_HD="+"
BOX_HV="+"

# Function to print information with label and value
print_info() {
    local label="$1"
    local value="$2"
    # Set fixed width to ensure right border alignment
    printf "${BLUE}${BOX_V}${NC} ${CYAN}%-18s${NC} ${WHITE}%-47s${NC} ${BLUE}${BOX_V}${NC}\n" "$label:" "$value"
}

# Function to get IP address information
get_ip_address() {
    # Try to get public IPv4 address from multiple services
    local ipv4=""
    local ipv4_sources=(
        "https://api.ipify.org"
        "https://ipv4.icanhazip.com"
        "https://v4.ident.me"
    )
    
    for source in "${ipv4_sources[@]}"; do
        ipv4=$(curl -s --connect-timeout 3 "$source" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ipv4" ]; then
            break
        fi
    done
    
    # Try to get public IPv6 address from multiple services
    local ipv6=""
    local ipv6_sources=(
        "https://api6.ipify.org"
        "https://ipv6.icanhazip.com"
        "https://v6.ident.me"
    )
    
    for source in "${ipv6_sources[@]}"; do
        ipv6=$(curl -s --connect-timeout 3 "$source" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ipv6" ]; then
            break
        fi
    done
    
    # Get local IP address
    local local_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
    
    # Display IP address information
    print_info "Public IPv4" "${ipv4:-Not detected}"
    print_info "Public IPv6" "${ipv6:-Not detected}"
    print_info "Local IPv4" "${local_ip:-Not detected}"
}

# Get system information
get_system_info() {
    # Get hostname
    local hostname=$(hostname)
    print_info "Hostname" "$hostname"
    
    # Get OS information
    local os_info=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d "=" -f 2 | tr -d '"')
    print_info "Operating System" "$os_info"
    
    # Get kernel version
    local kernel=$(uname -r)
    print_info "Kernel Version" "$kernel"
    
    # Get uptime
    local uptime=$(uptime -p | sed 's/up //')
    print_info "Uptime" "$uptime"
    
    # Get load average
    local load=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    print_info "Load Average" "$load"
    
    # Get CPU information
    local cpu_model=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')
    local cpu_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)
    local cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//' | awk '{printf "%.2f GHz", $1/1000}')
    
    print_info "CPU Model" "$cpu_model"
    print_info "CPU Cores" "$cpu_cores"
    print_info "CPU Frequency" "$cpu_freq"
    
    # Get memory usage
    local mem_total=$(free -h | grep "Mem" | awk '{print $2}')
    local mem_used=$(free -h | grep "Mem" | awk '{print $3}')
    local mem_free=$(free -h | grep "Mem" | awk '{print $4}')
    local mem_usage=$(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100}')
    
    print_info "Total Memory" "$mem_total"
    print_info "Used Memory" "$mem_used ($mem_usage)"
    print_info "Free Memory" "$mem_free"
    
    # Get swap information
    local swap_total=$(free -h | grep "Swap" | awk '{print $2}')
    local swap_used=$(free -h | grep "Swap" | awk '{print $3}')
    local swap_free=$(free -h | grep "Swap" | awk '{print $4}')
    
    print_info "Total Swap" "$swap_total"
    print_info "Used Swap" "$swap_used"
    print_info "Free Swap" "$swap_free"
    
    # Get disk usage
    echo -e "\n${BLUE}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${YELLOW}DISK USAGE${NC}                                        ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Header
    printf "${BLUE}${BOX_V}${NC} ${CYAN}%-14s %-10s %-12s %-12s %-10s${NC} ${BLUE}${BOX_V}${NC}\n" "Mount Point" "Size" "Used" "Available" "Use%"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Disk information
    df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop" | grep -v "Filesystem" | while read line; do
        local mount=$(echo $line | awk '{print $6}')
        local total=$(echo $line | awk '{print $2}')
        local used=$(echo $line | awk '{print $3}')
        local avail=$(echo $line | awk '{print $4}')
        local usage=$(echo $line | awk '{print $5}')
        
        printf "${BLUE}${BOX_V}${NC} ${WHITE}%-14s %-10s %-12s %-12s %-10s${NC} ${BLUE}${BOX_V}${NC}\n" "$mount" "$total" "$used" "$avail" "$usage"
    done
    
    # Get DNS servers
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${YELLOW}DNS SERVERS${NC}                                       ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    cat /etc/resolv.conf | grep "nameserver" | while read line; do
        local dns=$(echo $line | awk '{print $2}')
        printf "${BLUE}${BOX_V}${NC} ${WHITE}%-65s${NC} ${BLUE}${BOX_V}${NC}\n" "$dns"
    done
    
    # Get network interfaces
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${YELLOW}NETWORK INTERFACES${NC}                                ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Header
    printf "${BLUE}${BOX_V}${NC} ${CYAN}%-12s %-18s %-18s %-12s${NC} ${BLUE}${BOX_V}${NC}\n" "Interface" "IP Address" "MAC Address" "Status"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Network interface information
    ip -o addr show | grep -v "lo" | grep -v "docker" | grep -v "br-" | grep -v "veth" | while read line; do
        local interface=$(echo $line | awk '{print $2}')
        local ip=$(echo $line | awk '{print $4}')
        local mac=$(ip link show $interface | grep "link/ether" | awk '{print $2}')
        local status=$(ip link show $interface | grep -oP '(?<=state )[^ ]*')
        
        printf "${BLUE}${BOX_V}${NC} ${WHITE}%-12s %-18s %-18s %-12s${NC} ${BLUE}${BOX_V}${NC}\n" "$interface" "$ip" "$mac" "$status"
    done
}

# Function to show module header
show_module_header() {
    local title="$1"
    clear
    echo ""
    echo -e "${BLUE}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    
    # Use printf to center the title
    local title_text="${BOLD}${CYAN}ServerMaster${NC} - ${YELLOW}$title${NC}"
    local title_length=${#title_text}
    local padding=$(( (65 - title_length) / 2 ))
    
    printf "${BLUE}${BOX_V}${NC}%${padding}s%s%${padding}s${BLUE}${BOX_V}${NC}\n" "" "$title_text" ""
    
    echo -e "${BLUE}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    echo ""
}

# Function to show module footer
show_module_footer() {
    echo ""
    echo -e "${BLUE}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    
    # Use printf to center the footer text
    local footer_text="${YELLOW}Press Enter to return to the previous menu...${NC}"
    local footer_length=${#footer_text}
    local padding=$(( (65 - footer_length) / 2 ))
    
    printf "${BLUE}${BOX_V}${NC}%${padding}s%s%${padding}s${BLUE}${BOX_V}${NC}\n" "" "$footer_text" ""
    
    echo -e "${BLUE}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}${NC}"
    read
}

# Main function
main() {
    # Show module header
    show_module_header "System Information"
    
    # Show system information section
    echo -e "${BLUE}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${CYAN}BASIC SYSTEM INFO${NC}                                  ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Get system information
    get_system_info
    
    # Show IP address information section
    echo -e "\n${BLUE}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${GREEN}NETWORK INFORMATION${NC}                               ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    # Get IP address information
    get_ip_address
    
    # Try to get geolocation information
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    echo -e "${BLUE}${BOX_V}${NC}                      ${BOLD}${GREEN}GEOLOCATION INFO${NC}                                  ${BLUE}${BOX_V}${NC}"
    echo -e "${BLUE}${BOX_VL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VR}${NC}"
    
    ip_info=$(curl -s --connect-timeout 5 ipinfo.io 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$ip_info" ]; then
        country=$(echo "$ip_info" | grep -oP '"country": "\K[^"]+' 2>/dev/null)
        region=$(echo "$ip_info" | grep -oP '"region": "\K[^"]+' 2>/dev/null)
        city=$(echo "$ip_info" | grep -oP '"city": "\K[^"]+' 2>/dev/null)
        isp=$(echo "$ip_info" | grep -oP '"org": "\K[^"]+' 2>/dev/null)
        
        print_info "Country/Region" "${country:-Unknown}"
        print_info "Province/City" "${region:-Unknown}/${city:-Unknown}"
        print_info "ISP" "${isp:-Unknown}"
    else
        printf "${BLUE}${BOX_V}${NC} ${RED}%-65s${NC} ${BLUE}${BOX_V}${NC}\n" "Unable to get geolocation info, please check network connection"
    fi
    
    echo -e "${BLUE}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}${NC}"
    
    # Show module footer
    show_module_footer
}

# Execute main function
main "$@"