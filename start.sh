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

# 4. 100% FREE SELF-PING HACK TRICK
# This internal script hits its own external load balancer to fool the platform into thinking user traffic is happening.
# You MUST provide your app's public URL in the PUBLIC_URL environment variable!
if [ -n "$PUBLIC_URL" ]; then
  echo "Initiating Self-Pinging Hack. Target: $PUBLIC_URL"
  (
    while true; do
      # Ping the container every 3 minutes to guarantee it NEVER sleeps
      sleep 180 
      curl -s "$PUBLIC_URL/health" > /dev/null
      echo "Self-ping executed."
    done
  ) &
else
  echo "WARNING: PUBLIC_URL not set! Self-ping hack is inactive."
fi

# Keep container alive by waiting on all background processes
wait -n
