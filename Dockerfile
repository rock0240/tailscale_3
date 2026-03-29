FROM ubuntu:22.04

# 1. Prevent interactive prompts during apt-get
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install required system dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates iproute2 iptables nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Install Tailscale securely directly from their official script
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 4. Create necessary directory for tailscale state
RUN mkdir -p /var/lib/tailscale

# 5. Setup application directory
WORKDIR /app

# 6. Copy code to container
COPY package*.json ./
COPY server.js ./
COPY start.sh ./

# 7. Install Node dependencies (if any)
RUN npm install

# 8. Set execute permissions on script
RUN chmod +x start.sh

# 9. Expose port for keep-alive server (usually $PORT or 8080)
EXPOSE 8080

# 10. Execute startup script
CMD ["/bin/bash", "start.sh"]
