#!/bin/sh
set -e

# Sleep for 2 seconds to ensure container is ready
sleep 2

cd /home/container

# Set proper permissions
if [ -w /home/container ]; then
    chmod 755 /home/container
fi

# Process startup command
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Make internal Docker IP address available to processes.
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')

# Create necessary directories
mkdir -p /home/container/.cache /home/container/.config /home/container/.local

# Fix permissions
if [ -f "/home/container/.installed" ]; then
    chmod 644 /home/container/.installed
fi

# Check if already installed
if [ ! -e "/home/container/.installed" ]; then
    echo "Starting installation process..."
    /usr/local/bin/proot \
    --rootfs="/" \
    -0 -w "/root" \
    -b /dev -b /sys -b /proc \
    --kill-on-exit \
    /bin/sh "/install.sh" || exit 1
    touch /home/container/.installed
fi

# Run the startup helper script
echo "Starting helper script..."
exec /bin/sh /helper.sh
