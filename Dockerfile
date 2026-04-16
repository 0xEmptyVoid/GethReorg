# Use a stable Ubuntu base
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    lsb-release \
    bash \
    procps \
    vim \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and install specific Geth version (1.13.5-stable-916d6a44)
RUN wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.5-916d6a44.tar.gz \
    && tar -xvzf geth-linux-amd64-1.13.5-916d6a44.tar.gz \
    && mv geth-linux-amd64-1.13.5-916d6a44/geth /usr/local/bin/ \
    && rm -rf geth-linux-amd64-1.13.5-916d6a44 geth-linux-amd64-1.13.5-916d6a44.tar.gz

# Set working directory
WORKDIR /app

# Copy template files
COPY template/ /app/template/

# Copy the simulation script
COPY reorg_sim.sh /app/reorg_sim.sh
RUN chmod +x /app/reorg_sim.sh

# Entry point starts the interactive shell or the simulation script
# Using bash to allow easy interaction if needed
ENTRYPOINT ["/bin/bash", "/app/reorg_sim.sh"]
