#!/bin/sh

# X-Host VPS Main Runtime Script
# Downloaded from: https://github.com/Tarboobot2888/x

# Source common functions and variables
if [ -f "common.sh" ]; then
    . ./common.sh
elif [ -f "scripts/common.sh" ]; then
    . ./scripts/common.sh
else
    # Fallback if common.sh not available
    echo "❌ common.sh not found, using basic setup..."
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
    log() { 
        local level="$1"
        local msg="$2" 
        local color="$3"
        [ -z "$color" ] && color="$NC"
        printf "${color}[$level]${NC} $msg\n"
    }
fi

# Configuration
HOSTNAME="${SERVER_NAME:-X-Host-VPS}"
HISTORY_FILE="${HOME}/.xhost_vps_history"
MAX_HISTORY=1000

# Setup environment
setup_environment() {
    # Create essential directories
    mkdir -p "${HOME}/.cache" "${HOME}/.config" "${HOME}/.local" "${HOME}/tmp"
    
    # Create history file
    touch "$HISTORY_FILE"
    chmod 600 "$HISTORY_FILE"
    
    # Setup DNS if resolv.conf doesn't exist
    if [ ! -f "/etc/resolv.conf" ] || [ ! -s "/etc/resolv.conf" ]; then
        echo "nameserver 1.1.1.1" > /etc/resolv.conf
        echo "nameserver 1.0.0.1" >> /etc/resolv.conf
    fi
}

# Function to handle cleanup on exit
cleanup() {
    log "INFO" "Session ended. Thank you for using X-Host VPS!" "$GREEN"
    exit 0
}

# Function to get formatted directory
get_formatted_dir() {
    current_dir="$PWD"
    case "$current_dir" in
        "$HOME"*)
            printf "~${current_dir#$HOME}"
        ;;
        *)
            printf "$current_dir"
        ;;
    esac
}

print_instructions() {
    log "INFO" "Type 'help' to view a list of available X-Host VPS commands." "$YELLOW"
}

# Function to print prompt
print_prompt() {
    user="$1"
    printf "\n${GREEN}${user}@${HOSTNAME}${NC}:${BLUE}$(get_formatted_dir)${NC}# "
}

# Function to save command to history
save_to_history() {
    cmd="$1"
    if [ -n "$cmd" ] && [ "$cmd" != "exit" ] && [ "$cmd" != "history" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $cmd" >> "$HISTORY_FILE"
        # Keep only last MAX_HISTORY lines
        if [ -f "$HISTORY_FILE" ]; then
            tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi
}

# Function reinstall the OS
reinstall() {    
    log "INFO" "Reinstalling the OS on X-Host VPS..." "$YELLOW"
    log "WARNING" "This will remove all data! Continue? (y/N)" "$RED"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        find / -mindepth 1 -maxdepth 1 ! -name "home" -exec rm -rf {} + 2>/dev/null || true
        log "INFO" "Reinstallation completed. Please restart the server." "$GREEN"
    else
        log "INFO" "Reinstallation cancelled." "$YELLOW"
    fi
}

# Function to show system status
show_system_status() {
    log "INFO" "X-Host VPS System Status:" "$GREEN"
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime 2>/dev/null || echo 'Not available')"
    echo "OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"' || uname -s)"
    
    echo ""
    echo "=== Resource Usage ==="
    # Memory
    if command -v free >/dev/null 2>&1; then
        free -h 2>/dev/null || echo "Memory info not available"
    else
        echo "Memory: free command not available"
    fi
    
    # Disk
    if command -v df >/dev/null 2>&1; then
        df -h / 2>/dev/null || echo "Disk info not available"
    else
        echo "Disk: df command not available"
    fi
    
    # Processes
    if command -v ps >/dev/null 2>&1; then
        echo ""
        echo "=== Top Processes ==="
        ps aux --sort=-%mem 2>/dev/null | head -n 6 || echo "Process info not available"
    fi
}

# Function to create a backup
create_backup() {
    log "INFO" "Backup feature would be available in full installation" "$YELLOW"
    log "INFO" "Please install a distribution first using the install script" "$YELLOW"
}

# Function to restore a backup
restore_backup() {
    log "INFO" "Restore feature would be available in full installation" "$YELLOW"
    log "INFO" "Please install a distribution first using the install script" "$YELLOW"
}

# Function to print initial banner
print_banner() {
    if command -v print_main_banner >/dev/null 2>&1; then
        print_main_banner
    else
        echo "========================================="
        echo "🚀 X-Host VPS - Professional Virtual Server"
        echo "📍 Powered by X-Host Cloud Services"
        echo "💻 Type 'help' for available commands"
        echo "========================================="
    fi
}

# Function to print a beautiful help message
print_help_message() {
    if command -v print_help_banner >/dev/null 2>&1; then
        print_help_banner
    else
        echo "=== X-Host VPS Available Commands ==="
        echo "🧹  clear, cls     - Clear the terminal screen"
        echo "🔌  exit          - Shutdown the container server"
        echo "📜  history       - Display command history"
        echo "🔄  reinstall     - Reinstall the operating system"
        echo "🔐  install-ssh   - Install custom SSH server"
        echo "📊  status        - Show detailed system status"
        echo "💾  backup        - Create a complete system backup"
        echo "📥  restore       - Restore from a system backup"
        echo "❓  help          - Display this help information"
        echo ""
        echo "💡 Powered by X-Host Cloud Services"
    fi
}

# Function to handle command execution
execute_command() {
    cmd="$1"
    user="$2"
    
    # Save command to history
    save_to_history "$cmd"
    
    # Handle special commands
    case "$cmd" in
        "update")
            log "INFO" "Updating X-Host VPS scripts..." "$YELLOW"
            if curl -s -L "https://raw.githubusercontent.com/Tarboobot2888/x/main/scripts/update_scripts.sh" -o /tmp/update.sh; then
                chmod +x /tmp/update.sh
                /tmp/update.sh
            else
                log "ERROR" "Failed to download update script" "$RED"
            fi
            print_prompt "$user"
            return 0
            ;;
        "disk")
            log "INFO" "Disk usage information:" "$GREEN"
            df -h
            print_prompt "$user"
            return 0
            ;;
        "memory")
            log "INFO" "Memory usage information:" "$GREEN"
            free -h
            print_prompt "$user"
            return 0
            ;;
        "network")
            log "INFO" "Network information:" "$GREEN"
            ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Network tools not available"
            print_prompt "$user"
            return 0
            ;;
        "ports")
            log "INFO" "Active ports:" "$GREEN"
            netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo "Port tools not available"
            print_prompt "$user"
            return 0
            ;;
        "clear"|"cls")
            printf "\033c"
            print_prompt "$user"
            return 0
            ;;
        "exit")
            cleanup
            ;;
        "history")
            if [ -f "$HISTORY_FILE" ]; then
                cat "$HISTORY_FILE" | tail -20
            else
                log "INFO" "No command history found." "$YELLOW"
            fi
            print_prompt "$user"
            return 0
            ;;
        "reinstall")
            reinstall
            print_prompt "$user"
            return 0
            ;;
        "sudo"*|"su"*)
            log "ERROR" "You are already running as root." "$RED"
            print_prompt "$user"
            return 0
            ;;
        "install-ssh")
            log "INFO" "SSH installation would be available in full installation" "$YELLOW"
            print_prompt "$user"
            return 0
            ;;
        "status")
            show_system_status
            print_prompt "$user"
            return 0
            ;;
        "backup")
            create_backup
            print_prompt "$user"
            return 0
            ;;
        "restore")
            log "ERROR" "No backup file specified. Usage: restore <backup_file>" "$RED"
            print_prompt "$user"
            return 0
            ;;
        "restore "*)
            backup_file=$(echo "$cmd" | cut -d' ' -f2-)
            restore_backup "$backup_file"
            print_prompt "$user"
            return 0
            ;;
        "help")
            print_help_message
            print_prompt "$user"
            return 0
            ;;
        "")
            # Empty command, just show prompt again
            print_prompt "$user"
            return 0
            ;;
        *)
            # Execute system command
            if eval "$cmd" 2>/dev/null; then
                print_prompt "$user"
                return 0
            else
                log "ERROR" "Command not found: $cmd" "$RED"
                print_prompt "$user"
                return 0
            fi
            ;;
    esac
}

# Function to run command prompt for a specific user
run_prompt() {
    user="$1"
    printf "> "
    read -r cmd
    execute_command "$cmd" "$user"
}

# Main execution
main() {
    # Setup environment
    setup_environment
    
    # Set up trap for clean exit
    trap cleanup INT TERM
    
    # Print the initial banner
    print_banner
    
    # Print the initial instructions
    print_instructions
    
    # Execute autorun.sh if it exists
    if [ -f "/autorun.sh" ] && [ -x "/autorun.sh" ]; then
        /autorun.sh
    elif [ -f "autorun.sh" ] && [ -x "autorun.sh" ]; then
        ./autorun.sh
    fi
    
    # Print initial prompt
    print_prompt "user"
    
    # Main command loop
    while true; do
        run_prompt "user"
    done
}

# Start main function
main
