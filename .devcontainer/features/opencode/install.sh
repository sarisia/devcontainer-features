#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "curl -fsSL https://opencode.ai/install | bash" 2>&1

# opencode does not make symlink to ~/.local/bin (which claude code does)
su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.local/bin" 2>&1
ln -sf /home/${_REMOTE_USER}/.opencode/bin/opencode /home/${_REMOTE_USER}/.local/bin

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'rm -rf ~/.claude && ln -sf /mnt/.claude ~/.claude'
su ${_REMOTE_USER} -c 'mkdir -p ~/.local/share && rm -rf ~/.local/share/opencode && ln -sf /mnt/opencode ~/.local/share/opencode'


