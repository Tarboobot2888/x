#!/bin/sh
set -e

# X-Host VPS Helper Script
# Downloaded from: https://github.com/Tarboobot2888/x

ensure_run_script_exists() {
    echo "🔧 Ensuring scripts are available..."
    
    # Create home directory if it doesn't exist
    mkdir -p "$HOME"
    
    # Check and download essential scripts with fallbacks
    for script in common.sh run.sh; do
        if [ ! -f "$HOME/$script" ] || [ ! -s "$HOME/$script" ]; then
            echo "📥 Downloading $script from GitHub..."
            if curl -s -L --connect-timeout 10 "https://raw.githubusercontent.com/Tarboobot2888/x/main/scripts/$script" -o "$HOME/$script"; then
                chmod +x "$HOME/$script"
                echo "✅ $script downloaded successfully"
            else
                echo "❌ Failed to download $script, creating fallback..."
                # Create essential fallback
                case "$script" in
                    "common.sh")
                        cat > "$HOME/common.sh" << 'EOF'
#!/bin/sh
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log() { 
    local level="$1"
    local msg="$2" 
    local color="$3"
    [ -z "$color" ] && color="$NC"
    printf "${color}[$level]${NC} $msg\n"
}
print_banner() {
    echo "========================================="
    echo "🚀 X-Host VPS - Professional Virtual Server"
    echo "📍 Powered by X-Host Cloud Services"
    echo "========================================="
}
EOF
                        ;;
                    "run.sh")
                        cat > "$HOME/run.sh" << 'EOF'
#!/bin/sh
cd /home/container
if [ -f "common.sh" ]; then
    . ./common.sh
    print_banner
else
    echo "🚀 X-Host VPS - Professional Virtual Server"
    echo "📍 Powered by X-Host Cloud Services"
fi
echo "System is ready!"
echo "Type 'help' for available commands"
exec /bin/sh
EOF
                        ;;
                esac
                chmod +x "$HOME/$script"
            fi
        fi
    done
    
    # Ensure scripts are executable
    chmod +x "$HOME/common.sh" "$HOME/run.sh" 2>/dev/null || true
}

# Parse port configuration
parse_ports() {
    config_file="$HOME/vps.config"
    port_args=""
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "ℹ️  No vps.config file found, using default settings."
        return
    fi
    
    echo "🔍 Reading port configuration..."
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        case "$key" in
            ""|"#"*)
                continue
                ;;
        esac
        
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')
        
        [ "$key" = "internalip" ] && continue
        
        # Check if key matches port pattern and value is not empty
        case "$key" in
            port[0-9]*)
                if [ -n "$value" ]; then
                    # Check if value is a number between 1 and 65535
                    case "$value" in
                        *[!0-9]*)
                            echo "⚠️  Warning: Port $key has invalid value: $value"
                            ;;
                        *)
                            if [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                                port_args="$port_args -p $value:$value"
                                echo "🔌 Mapping port: $value"
                            else
                                echo "⚠️  Warning: Port $value is out of range (1-65535)"
                            fi
                            ;;
                    esac
                fi
                ;;
        esac
    done < "$config_file"
    
    echo "$port_args"
}

# Check and setup PRoot
setup_proot() {
    echo "🔧 Setting up PRoot environment..."
    
    # Check if PRoot is available
    if [ ! -x "/usr/local/bin/proot" ]; then
        echo "📥 PRoot not found, attempting to install..."
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) ARCH="amd64" ;;
            aarch64) ARCH="arm64" ;;
            riscv64) ARCH="riscv64" ;;
            *) ARCH="amd64" ;;
        esac
        
        mkdir -p /usr/local/bin
        if curl -s -L --connect-timeout 10 "https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-$ARCH-static" -o /usr/local/bin/proot; then
            chmod 755 /usr/local/bin/proot
            echo "✅ PRoot installed successfully"
        else
            echo "❌ Failed to download PRoot, checking package manager..."
            # Try package manager installation
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update -qq && apt-get install -y -qq proot >/dev/null 2>&1 && echo "✅ PRoot installed via apt" || echo "❌ Failed to install PRoot"
            elif command -v apk >/dev/null 2>&1; then
                apk add --no-cache proot >/dev/null 2>&1 && echo "✅ PRoot installed via apk" || echo "❌ Failed to install PRoot"
            else
                echo "⚠️  PRoot not available, some features may not work"
            fi
        fi
    fi
    
    if [ -x "/usr/local/bin/proot" ] || command -v proot >/dev/null 2>&1; then
        echo "✅ PRoot is ready"
        return 0
    else
        echo "❌ PRoot is not available"
        return 1
    fi
}

# Execute PRoot environment
exec_proot() {
    echo "🚀 Initializing X-Host VPS Environment..."
    
    # Ensure home directory exists and has proper permissions
    mkdir -p "${HOME}"
    chmod 755 "${HOME}"
    
    # Setup PRoot
    if ! setup_proot; then
        echo "⚠️  Continuing without PRoot - limited functionality"
        echo "📍 Starting basic shell environment..."
        cd "$HOME"
        if [ -f "run.sh" ] && [ -x "run.sh" ]; then
            exec ./run.sh
        else
            exec /bin/sh
        fi
        return
    fi
    
    port_args=$(parse_ports)
    
    echo "🔧 Starting PRoot with ports: $port_args"
    
    # Source common functions if available
    if [ -f "$HOME/common.sh" ]; then
        . "$HOME/common.sh"
    fi
    
    # Use PRoot if available
    PROOT_CMD=$(command -v proot || echo "/usr/local/bin/proot")
    
    if [ -x "$PROOT_CMD" ]; then
        exec $PROOT_CMD \
        --rootfs="${HOME}" \
        -0 -w "${HOME}" \
        -b /dev -b /sys -b /proc \
        -b /etc/resolv.conf:/etc/resolv.conf \
        $port_args \
        --kill-on-exit \
        /bin/sh "$HOME/run.sh"
    else
        echo "❌ PRoot command not found or not executable"
        echo "🔧 Starting fallback shell..."
        cd "$HOME"
        exec /bin/sh
    fi
}

# Main execution
echo "========================================="
echo "🎉 X-Host VPS Starting..."
echo "📍 Scripts Source: GitHub/Tarboobot2888/x"
echo "🚀 Environment: PRoot + Docker"
echo "========================================="

ensure_run_script_exists
exec_proot
