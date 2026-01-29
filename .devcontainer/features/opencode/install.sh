#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "curl -fsSL https://opencode.ai/install | bash" 2>&1

# opencode does not make symlink to ~/.local/bin (which claude code does)
su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.local/bin" 2>&1
ln -sf /home/${_REMOTE_USER}/.opencode/bin/opencode /home/${_REMOTE_USER}/.local/bin

# remove ~/.claude and use bind mount from host instead
rm -rf /home/${_REMOTE_USER}/.local/share/opencode
su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.local/share" 2>&1
ln -sf /opencode /home/${_REMOTE_USER}/.local/share
