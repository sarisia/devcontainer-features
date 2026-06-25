#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "npm i -g @openai/codex" 2>&1

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'rm -rf ~/.codex && ln -sfn /mnt/.codex ~/.codex'
su ${_REMOTE_USER} -c 'rm -rf ~/.agents && ln -sfn /mnt/.agents ~/.agents'
