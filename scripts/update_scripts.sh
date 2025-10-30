#!/bin/bash
# X-Host VPS Script Updater

echo "🔄 Updating X-Host VPS scripts from GitHub..."

SCRIPTS_URL="https://raw.githubusercontent.com/Tarboobot2888/x/main/scripts"

for script in entrypoint.sh install.sh helper.sh run.sh common.sh; do
    echo "Updating $script..."
    if curl -s -L "$SCRIPTS_URL/$script" -o "scripts/$script"; then
        chmod +x "scripts/$script"
        echo "✅ $script updated successfully"
    else
        echo "❌ Failed to update $script"
    fi
done

echo "🎉 Script update completed!"