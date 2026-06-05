#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "curl -fsSL https://claude.ai/install.sh | bash" 2>&1

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'rm -rf ~/.claude && ln -sf /mnt/.claude ~/.claude && ln -sf /mnt/.claude.json ~/.claude.json'
