#!/bin/sh

# X-Host VPS Common Functions and Variables
# Downloaded from: https://github.com/Tarboobot2888/x

# Common color definitions
PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Common logger function
log() {
    level=$1
    message=$2
    color=$3
    
    if [ -z "$color" ]; then
        color="$NC"
    fi
    
    printf "${color}[$level]${NC} $message\n"
}

# Function to detect architecture
detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            echo "amd64"
        ;;
        aarch64)
            echo "arm64"
        ;;
        riscv64)
            echo "riscv64"
        ;;
        *)
            log "ERROR" "Unsupported CPU architecture: $ARCH" "$RED" >&2
            return 1
        ;;
    esac
}

# Function to check and install required packages
check_dependencies() {
    log "INFO" "Checking system dependencies..." "$YELLOW"
    
    local missing_packages=""
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_packages="$missing_packages curl"
    fi
    
    # Check for tar
    if ! command -v tar >/dev/null 2>&1; then
        missing_packages="$missing_packages tar"
    fi
    
    # Check for wget
    if ! command -v wget >/dev/null 2>&1; then
        missing_packages="$missing_packages wget"
    fi
    
    if [ -n "$missing_packages" ]; then
        log "INFO" "Installing required packages: $missing_packages" "$YELLOW"
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq $missing_packages >/dev/null 2>&1
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache $missing_packages >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y -q $missing_packages >/dev/null 2>&1
        else
            log "ERROR" "Cannot install required packages. Please install manually: $missing_packages" "$RED"
            return 1
        fi
    fi
    
    log "SUCCESS" "All dependencies are satisfied" "$GREEN"
    return 0
}

# Function to print the main banner
print_main_banner() {
    printf "\033c"
    printf "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║              ${PURPLE}${BOLD}██╗  ██╗${CYAN}    ${PURPLE}${BOLD}██╗  ██╗${CYAN}    ${PURPLE}${BOLD} ██████╗ ███████╗████████╗${CYAN}                   ║${NC}\n"
    printf "${CYAN}║              ${PURPLE}${BOLD}╚██╗██╔╝${CYAN}    ${PURPLE}${BOLD}╚██╗██╔╝${CYAN}    ${PURPLE}${BOLD}██╔═══██╗██╔════╝╚══██╔══╝${CYAN}                   ║${NC}\n"
    printf "${CYAN}║               ${PURPLE}${BOLD}╚███╔╝${CYAN}      ${PURPLE}${BOLD}╚███╔╝${CYAN}      ${PURPLE}${BOLD}██║   ██║███████╗   ██║${CYAN}                      ║${NC}\n"
    printf "${CYAN}║               ${PURPLE}${BOLD}██╔██╗${CYAN}      ${PURPLE}${BOLD}██╔██╗${CYAN}      ${PURPLE}${BOLD}██║   ██║╚════██║   ██║${CYAN}                      ║${NC}\n"
    printf "${CYAN}║              ${PURPLE}${BOLD}██╔╝ ██╗${CYAN}    ${PURPLE}${BOLD}██╔╝ ██╗${CYAN}    ${PURPLE}${BOLD}╚██████╔╝███████║   ██║${CYAN}                      ║${NC}\n"
    printf "${CYAN}║              ${PURPLE}${BOLD}╚═╝  ╚═╝${CYAN}    ${PURPLE}${BOLD}╚═╝  ╚═╝${CYAN}    ${PURPLE}${BOLD} ╚═════╝ ╚══════╝   ╚═╝${CYAN}                      ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║                     ${GREEN}${BOLD}🚀 X-Host Virtual Private Server 🚀${CYAN}                         ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║                      ${GREEN}✨  Lightweight • Fast • Reliable ✨${CYAN}                       ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║                          ${DIM}© 2024 X-Host Cloud Services${CYAN}                           ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

# Function to print the help banner
print_help_banner() {
    printf "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║                        ${WHITE}${BOLD}📋 X-Host VPS COMMANDS 📋${BLUE}                               ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╠═══════════════════════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║  ${CYAN}🧹  ${YELLOW}${BOLD}clear, cls${NC}        ${GREEN}▶  ${WHITE}Clear the terminal screen${BLUE}                            ║${NC}\n"
    printf "${BLUE}║  ${RED}🔌  ${YELLOW}${BOLD}exit${NC}              ${GREEN}▶  ${WHITE}Shutdown the container server${BLUE}                        ║${NC}\n"
    printf "${BLUE}║  ${PURPLE}📜  ${YELLOW}${BOLD}history${NC}           ${GREEN}▶  ${WHITE}Display command history${BLUE}                              ║${NC}\n"
    printf "${BLUE}║  ${CYAN}🔄  ${YELLOW}${BOLD}reinstall${NC}         ${GREEN}▶  ${WHITE}Reinstall the operating system${BLUE}                       ║${NC}\n"
    printf "${BLUE}║  ${GREEN}🔐  ${YELLOW}${BOLD}install-ssh${NC}       ${GREEN}▶  ${WHITE}Install custom SSH server${BLUE}                            ║${NC}\n"
    printf "${BLUE}║  ${BLUE}📊  ${YELLOW}${BOLD}status${NC}            ${GREEN}▶  ${WHITE}Show detailed system status${BLUE}                          ║${NC}\n"
    printf "${BLUE}║  ${YELLOW}💾  ${YELLOW}${BOLD}backup${NC}            ${GREEN}▶  ${WHITE}Create a complete system backup${BLUE}                      ║${NC}\n"
    printf "${BLUE}║  ${PURPLE}📥  ${YELLOW}${BOLD}restore${NC}           ${GREEN}▶  ${WHITE}Restore from a system backup${BLUE}                         ║${NC}\n"
    printf "${BLUE}║  ${WHITE}❓  ${YELLOW}${BOLD}help${NC}              ${GREEN}▶  ${WHITE}Display this help information${BLUE}                        ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╠═══════════════════════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║                    ${DIM}💡 Powered by X-Host Cloud Services${BLUE}                      ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

# Function to validate network connectivity
check_network_connectivity() {
    log "INFO" "Checking network connectivity..." "$YELLOW"
    if curl -s --connect-timeout 10 --head https://github.com >/dev/null; then
        log "SUCCESS" "Network connectivity confirmed" "$GREEN"
        return 0
    else
        log "WARNING" "Limited network connectivity detected" "$YELLOW"
        return 1
    fi
}

# Function to setup environment
setup_environment() {
    log "INFO" "Setting up environment..." "$YELLOW"
    
    # Create essential directories
    mkdir -p /home/container/{scripts,logs,tmp,.cache,.config,.local}
    
    # Set proper permissions
    chmod 755 /home/container /home/container/{scripts,logs,tmp,.cache,.config,.local} 2>/dev/null || true
    
    # Fix group issues
    if [ -f "/etc/group" ] && ! grep -q "^container:" /etc/group; then
        echo "container:x:1000:" >> /etc/group 2>/dev/null || true
    fi
    
    log "SUCCESS" "Environment setup completed" "$GREEN"
}
