#!/bin/bash
# =============================================================================
# post-onboard.sh
# CLAW Stack Field Notes - Post-Onboard Fix Sequence
# https://github.com/AdamMaGill/claw-stack-field-notes
#
# Run after every nemoclaw onboard. Three fixes that every deployment needs
# but none of the documentation mentions.
#
# Tested: NemoClaw main, OpenShell v0.0.24, Ubuntu 24.04, April 2026
# Run as: bash post-onboard.sh
#
# See Post 3 at adammagill.substack.com for the full context.
# =============================================================================

set -euo pipefail

# Set your username and sandbox name here
USERNAME="${1:-}"
SANDBOX_NAME="${2:-}"

if [ -z "$USERNAME" ] || [ -z "$SANDBOX_NAME" ]; then
    echo "Usage: bash post-onboard.sh <your-username> <sandbox-name>"
    echo "Example: bash post-onboard.sh myuser my-assistant"
    exit 1
fi

echo "Running post-onboard fixes for user=$USERNAME sandbox=$SANDBOX_NAME"
echo ""

echo "[1/3] Syncing sandbox registry from root to $USERNAME..."
if [ -f /root/.nemoclaw/sandboxes.json ]; then
    sudo cp /root/.nemoclaw/sandboxes.json /home/$USERNAME/.nemoclaw/sandboxes.json
    sudo chown $USERNAME:$USERNAME /home/$USERNAME/.nemoclaw/sandboxes.json
    echo "Registry synced."
else
    echo "WARNING: /root/.nemoclaw/sandboxes.json not found. Run nemoclaw onboard first."
    exit 1
fi

echo ""
echo "[2/3] Applying nemoclaw-services User=$USERNAME drop-in..."
DROPIN_DIR="/etc/systemd/system/nemoclaw-services.service.d"
DROPIN_FILE="$DROPIN_DIR/override.conf"

sudo mkdir -p "$DROPIN_DIR"

sudo tee "$DROPIN_FILE" > /dev/null << EOF
[Service]
User=$USERNAME
Group=$USERNAME
EOF

sudo systemctl daemon-reload
echo "Drop-in applied. nemoclaw-services will run as $USERNAME."

echo ""
echo "[3/3] Verifying SANDBOX_NAME in /etc/nemoclaw.env..."
if sudo grep -q "^SANDBOX_NAME=" /etc/nemoclaw.env 2>/dev/null; then
    CURRENT=$(sudo grep "^SANDBOX_NAME=" /etc/nemoclaw.env | cut -d= -f2)
    if [ "$CURRENT" != "$SANDBOX_NAME" ]; then
        echo "SANDBOX_NAME is set to '$CURRENT' but expected '$SANDBOX_NAME'."
        echo "Updating..."
        sudo sed -i "s/^SANDBOX_NAME=.*/SANDBOX_NAME=$SANDBOX_NAME/" /etc/nemoclaw.env
        echo "Updated SANDBOX_NAME to $SANDBOX_NAME."
    else
        echo "SANDBOX_NAME is correctly set to $SANDBOX_NAME."
    fi
elif sudo grep -q "^NEMOCLAW_SANDBOX=" /etc/nemoclaw.env 2>/dev/null; then
    echo "Found NEMOCLAW_SANDBOX instead of SANDBOX_NAME. Correcting..."
    sudo sed -i "s/^NEMOCLAW_SANDBOX=.*/SANDBOX_NAME=$SANDBOX_NAME/" /etc/nemoclaw.env
    echo "Corrected to SANDBOX_NAME=$SANDBOX_NAME."
else
    echo "WARNING: SANDBOX_NAME not found in /etc/nemoclaw.env. Adding..."
    echo "SANDBOX_NAME=$SANDBOX_NAME" | sudo tee -a /etc/nemoclaw.env > /dev/null
    echo "Added SANDBOX_NAME=$SANDBOX_NAME."
fi

echo ""
echo "============================================="
echo "Post-onboard fixes complete."
echo "============================================="
echo ""
echo "Next steps:"
echo "1. Restart the bridge:  sudo pkill -f telegram-bridge"
echo "                        sudo systemctl restart nemoclaw-services"
echo "2. Verify bridge user:  ps aux | grep telegram-bridge | grep -v grep | awk '{print \$1}'"
echo "   Expected: $USERNAME"
echo "3. Verify sandbox:      nemoclaw $SANDBOX_NAME status"
echo ""
echo "Valid as of: NemoClaw main, OpenShell v0.0.24, April 2026"
echo "See: https://adammagill.substack.com/p/first-contact-getting-nemoclaw-running"
echo "============================================="
