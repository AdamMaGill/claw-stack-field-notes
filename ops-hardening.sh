#!/bin/bash
# =============================================================================
# vps-hardening.sh
# CLAW Stack Field Notes - VPS Foundation Hardening
# https://github.com/AdamMaGill/claw-stack-field-notes
#
# Tested: Ubuntu 24.04 LTS, Hostinger KVM2, April 2026
# Run as: sudo bash vps-hardening.sh
#
# MANUAL STEPS REQUIRED (browser-based, cannot be scripted):
#   1. Cloudflare account setup and DNS migration
#   2. Zero Trust tunnel creation (cloudflare.com/zero-trust)
#   3. mTLS client certificate generation (one per device)
#   4. WAF rule: block requests without valid client cert
#   5. Google OAuth configuration as identity provider
#   6. Passkey enrollment per device
#
# This script handles everything that CAN be automated.
# See Post 2 at adammagill.substack.com for the full walkthrough.
# =============================================================================

set -euo pipefail

echo "[1/7] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

echo "[2/7] Configuring UFW firewall..."
apt-get install -y ufw -qq
ufw default deny incoming
ufw default allow outgoing
# No inbound ports opened - all access via Cloudflare tunnel
ufw --force enable
echo "UFW enabled. No inbound ports open."

echo "[3/7] Hardening SSH configuration..."
# Main sshd_config
cat > /etc/ssh/sshd_config.d/hardening.conf << 'EOF'
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowUsers <your-username> sysrescue
EOF

# Fix the cloud-init override that silently re-enables password auth
# Ubuntu cloud images ship this file - it overrides sshd_config if not corrected
CLOUD_INIT_SSH="/etc/ssh/sshd_config.d/50-cloud-init.conf"
if [ -f "$CLOUD_INIT_SSH" ]; then
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$CLOUD_INIT_SSH"
    echo "Fixed 50-cloud-init.conf override."
else
    echo "50-cloud-init.conf not found - skipping."
fi

systemctl restart sshd
echo "SSH hardened."

echo "[4/7] Installing and configuring auditd..."
apt-get install -y auditd audispd-plugins -qq

cat > /etc/audit/rules.d/hardening.rules << 'EOF'
# Authentication events
-w /var/log/auth.log -p wa -k auth_events
-w /etc/passwd -p wa -k user_changes
-w /etc/group -p wa -k group_changes
-w /etc/shadow -p wa -k shadow_changes

# Privilege escalation
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes
-a always,exit -F arch=b64 -S setuid -k privilege_escalation

# SSH config changes
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/sshd_config.d/ -p wa -k ssh_config

# Cloudflared config
-w /etc/cloudflared/ -p wa -k cloudflared_config

# Privileged commands
-a always,exit -F arch=b64 -S execve -F euid=0 -k privileged_commands
EOF

systemctl enable auditd
systemctl restart auditd
echo "auditd configured."

echo "[5/7] Configuring unattended-upgrades (security only)..."
apt-get install -y unattended-upgrades -qq

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

systemctl enable unattended-upgrades
echo "Unattended-upgrades configured for security patches only."

echo "[6/7] Installing cloudflared..."
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
    https://pkg.cloudflare.com/cloudflared any main" \
    | tee /etc/apt/sources.list.d/cloudflared.list

apt-get update -qq
apt-get install -y cloudflared -qq
echo "cloudflared installed. Complete tunnel setup manually in Cloudflare dashboard."

echo "[7/7] Creating break-glass account..."
if ! id "sysrescue" &>/dev/null; then
    useradd -m -s /bin/bash sysrescue
    usermod -aG sudo sysrescue
    echo "sysrescue account created. Set password manually: passwd sysrescue"
    echo "Add SSH public key manually: /home/sysrescue/.ssh/authorized_keys"
else
    echo "sysrescue account already exists."
fi

echo ""
echo "============================================="
echo "Hardening complete. Manual steps remaining:"
echo "============================================="
echo ""
echo "1. Set sysrescue password:       passwd sysrescue"
echo "2. Add SSH keys for <your-username> and sysrescue"
echo "3. Complete Cloudflare Zero Trust setup (browser):"
echo "   - Create tunnel and connect to this VPS"
echo "   - Generate mTLS certs (one per device)"
echo "   - Configure WAF rule to block uncerted requests"
echo "   - Set up Google OAuth as identity provider"
echo "   - Enroll passkeys per device"
echo "4. Verify SSH access via tunnel before closing current session"
echo "5. Take a VPS snapshot (Hostinger hPanel) before proceeding"
echo ""
echo "Valid as of: Ubuntu 24.04 LTS, April 2026"
echo "See: https://adammagill.substack.com/p/securing-the-foundation"
echo "============================================="
