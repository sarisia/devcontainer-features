#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "npm i -g opencode-ai" 2>&1

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'rm -rf ~/.claude && ln -sf /mnt/.claude ~/.claude'
su ${_REMOTE_USER} -c 'mkdir -p ~/.local/share && rm -rf ~/.local/share/opencode && ln -sf /mnt/opencode ~/.local/share/opencode'


