#!/bin/bash
set -e

echo "Starting Tailscale node for Claw.cloud container environment..."

# 1. Start tailscaled daemon in userspace mode
# (This acts as a transparent proxy without requiring kernel TUN/TAP access)
echo "Starting tailscaled daemon in background..."
tailscaled --state=/var/lib/tailscale/tailscaled.state \
           --tun=userspace-networking \
           --socks5-server=localhost:1055 &

# 2. Run authentication in background so it doesn't block the keep-alive server
(
  echo "Waiting 5 seconds for daemon to boot before authenticating..."
  sleep 5
  if [ -z "${TAILSCALE_AUTH_KEY}" ]; then
    echo "ERROR: TAILSCALE_AUTH_KEY environment variable is not set! Tailscale will not connect."
  else
    echo "Authenticating with Tailscale..."
    tailscale up --authkey=${TAILSCALE_AUTH_KEY} \
                 --hostname=claw-cloud-node \
                 --advertise-exit-node \
                 --ssh \
                 --accept-dns=false
    echo "Tailscale is authenticated and advertising as an exit node!"
  fi
) &

# 3. Start keep-alive server in background
echo "Starting keep-alive web server to satisfy Cloud Run requirements..."
npm start &


# Keep container alive by running the web server in the foreground instead of waiting
echo "Bringing keep-alive server to foreground..."
wait
