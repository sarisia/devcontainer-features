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

# The bind mounts do not exist at image build time, so linking has to happen at
# runtime; ship the script and let postStartCommand run it.
SHARE=/usr/local/share/claude-feature
install -d -m 0755 "$SHARE"
install -m 0644 "$(dirname "$0")/link-mounts.sh" "$SHARE/link-mounts.sh"
install -m 0755 "$(dirname "$0")/links.sh" "$SHARE/links.sh"

# Feature options are only in the environment during install; persist for postStart.
printf '%s\n' "${EXCLUDE:-}" > "$SHARE/exclude"
chmod 0644 "$SHARE/exclude"
