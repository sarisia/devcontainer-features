#!/bin/bash

set -euo pipefail

CHANNEL="${CHANNEL:-latest}"

# Install via the official Claude Code apt repository
# https://code.claude.com/docs/en/setup#install-with-linux-package-managers
apt-get update
apt-get install -y curl

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
    -o /etc/apt/keyrings/claude-code.asc

echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/${CHANNEL} ${CHANNEL} main" \
    | tee /etc/apt/sources.list.d/claude-code.list > /dev/null

apt-get update
apt-get install -y claude-code

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'rm -rf ~/.claude && ln -sf /mnt/.claude ~/.claude && ln -sf /mnt/.claude.json ~/.claude.json'
