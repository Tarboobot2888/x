#!/bin/sh
set -e

ensure_run_script_exists() {
    # Create home directory if it doesn't exist
    mkdir -p "$HOME"
    
    # Check if common.sh exists in the container, if not copy it again
    if [ ! -f "$HOME/common.sh" ]; then
        cp /common.sh "$HOME/common.sh"
        chmod +x "$HOME/common.sh"
    fi
    
    # Check if run.sh exists in the container, if not copy it again
    if [ ! -f "$HOME/run.sh" ]; then
        cp /run.sh "$HOME/run.sh"
        chmod +x "$HOME/run.sh"
    fi
    
    # Ensure scripts are executable
    chmod +x "$HOME/common.sh" "$HOME/run.sh" 2>/dev/null || true
}

# Parse port configuration
parse_ports() {
    config_file="$HOME/vps.config"
    port_args=""
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "No vps.config file found, using default settings."
        return
    fi
    
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
                            # Not a number, skip
                            echo "Warning: Port $key has invalid value: $value"
                            ;;
                        *)
                            # It's a number, check range
                            if [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                                port_args="$port_args -p $value:$value"
                                echo "Mapping port: $value"
                            else
                                echo "Warning: Port $value is out of range (1-65535)"
                            fi
                            ;;
                    esac
                fi
                ;;
        esac
    done < "$config_file"
    
    echo "$port_args"
}

# Execute PRoot environment
exec_proot() {
    echo "Initializing X-Host VPS PRoot environment..."
    
    # Ensure home directory exists and has proper permissions
    mkdir -p "${HOME}"
    chmod 755 "${HOME}"
    
    port_args=$(parse_ports)
    
    echo "Starting PRoot with ports: $port_args"
    
    exec /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc \
    -b /etc/resolv.conf:/etc/resolv.conf \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

# Main execution
ensure_run_script_exists
exec_proot
