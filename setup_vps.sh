#!/bin/bash
set -e

# ==============================================================================
# Claw.cloud Standard Root VPS Setup Script for Tailscale Exit Node
# Use this script if you purchased a standard Linux VM on Claw.cloud
# ==============================================================================

echo "==========================================================="
echo "   Tailscale Exit Node Setup for Standard Linux VPS"
echo "==========================================================="

# 1. Check if user is root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., sudo ./setup_vps.sh)"
  exit 1
fi

# 2. Request Authorization Key if not provided in env
if [ -z "${TAILSCALE_AUTH_KEY}" ]; then
  read -p "Enter your Tailscale Auth Key (tskey-auth-...): " TAILSCALE_AUTH_KEY
fi

if [ -z "${TAILSCALE_AUTH_KEY}" ]; then
  echo "ERROR: Auth key is required to proceed. Exiting."
  exit 1
fi

echo "[1/4] Configuring IP Forwarding for Exit Node routing..."
# Enable IP forwarding persistently
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf >/dev/null
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf >/dev/null
sysctl -p /etc/sysctl.d/99-tailscale.conf

echo "[2/4] Installing Tailscale using official script..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[3/4] Authenticating and advertising as Exit Node..."
tailscale up --authkey=${TAILSCALE_AUTH_KEY} \
             --hostname=claw-root-vps \
             --advertise-exit-node \
             --ssh

echo "[4/4] Setup Complete!"
echo "Your Claw.cloud Root VPS is now a functioning Tailscale Exit node."
echo "Note: You no longer need a 'keep-alive' server because this is a standard root VM."
echo "You can view its status by running: sudo tailscale status"
