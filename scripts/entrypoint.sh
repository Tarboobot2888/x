#!/bin/sh
set -e

# X-Host VPS Entrypoint Script
# Downloaded from: https://github.com/Tarboobot2888/x

echo "========================================="
echo "🚀 X-Host VPS Container Initializing..."
echo "📍 GitHub: https://github.com/Tarboobot2888/x"
echo "========================================="

# Wait for container to be fully ready
sleep 3

cd /home/container

# Fix group permissions issue immediately
if [ -f "/etc/group" ]; then
    if ! grep -q ":998:" /etc/group; then
        echo "fixgroups:x:998:" >> /etc/group 2>/dev/null || true
    fi
    if ! grep -q "^container:" /etc/group; then
        echo "container:x:1000:1000" >> /etc/group 2>/dev/null || true
    fi
fi

# Set proper permissions
if [ -w /home/container ]; then
    chmod 755 /home/container
    chown 1000:1000 /home/container 2>/dev/null || true
fi

# Process startup command
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Make internal Docker IP address available to processes.
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')

# Create necessary directories with proper permissions
mkdir -p /home/container/{scripts,logs,tmp,.cache,.config,.local}
chmod 755 /home/container/{scripts,logs,tmp,.cache,.config,.local}

# Setup environment variables
export HOME=/home/container
export USER=container
export SHELL=/bin/sh
export PATH=$PATH:/usr/local/bin

# Check if we should auto-update scripts
if [ "${AUTO_UPDATE_SCRIPTS:-true}" = "true" ]; then
    echo "🔄 Auto-updating scripts from GitHub..."
    
    SCRIPTS_URL="https://raw.githubusercontent.com/Tarboobot2888/x/main/scripts"
    for script in common.sh run.sh helper.sh; do
        echo "Updating $script..."
        if curl -s -L --connect-timeout 10 "$SCRIPTS_URL/$script" -o "/home/container/scripts/$script"; then
            chmod +x "/home/container/scripts/$script"
            echo "✅ $script updated"
        else
            echo "❌ Failed to update $script, using local version if available"
        fi
    done
fi

# Check if installation is needed
if [ ! -e "/home/container/.installed" ]; then
    echo "📦 Starting installation process..."
    if [ -f "/home/container/scripts/install.sh" ] && [ -x "/home/container/scripts/install.sh" ]; then
        if /bin/sh "/home/container/scripts/install.sh"; then
            touch /home/container/.installed
            echo "✅ Installation completed successfully"
        else
            echo "❌ Installation failed, continuing with basic setup..."
        fi
    else
        echo "⚠️ install.sh not found or not executable, skipping installation"
    fi
fi

# Run the startup helper script
echo "🎯 Starting X-Host VPS Environment..."
if [ -f "/home/container/scripts/helper.sh" ] && [ -x "/home/container/scripts/helper.sh" ]; then
    exec /bin/sh /home/container/scripts/helper.sh
else
    echo "❌ helper.sh not found or not executable"
    echo "🔧 Starting fallback shell environment..."
    cd /home/container
    exec /bin/sh
fi
