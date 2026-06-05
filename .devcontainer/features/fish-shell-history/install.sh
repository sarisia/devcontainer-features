#!/bin/bash

set -euo pipefail

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'mkdir -p ~/.local/share/fish && ln -sf /mnt/fish-shell-history/fish_history ~/.local/share/fish/fish_history'
