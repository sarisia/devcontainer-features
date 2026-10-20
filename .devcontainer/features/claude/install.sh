#!/bin/bash

set -euo pipefail

CHANNEL="${CHANNEL:-latest}"

# A binary already on PATH belongs to someone else -- the base image, another
# feature, or the user's dotfiles. Reinstalling over it either hard-fails (dpkg
# file conflict, npm EEXIST) or silently clobbers their copy, so leave it alone
# and skip only the install; the config below always runs.
#
# Checked as root AND as $_REMOTE_USER: `npm i -g` under nvm and native
# installers writing ~/.local/bin land on the remote user's PATH only.
find_bin() {
    p="$(command -v "$1" 2>/dev/null \
        || su "${_REMOTE_USER:-root}" -s /bin/sh -c "command -v \"$1\"" 2>/dev/null \
        || true)"
    [ -x "$p" ] && printf '%s\n' "$p"
}

if bin="$(find_bin claude)"; then
    echo "claude: already installed at ${bin}; skipping install"
else
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
fi

# A fresh named volume copies the ownership of its image mount point, so this
# hands both volumes to the remote user without a runtime chown.
REMOTE_USER="${_REMOTE_USER:-root}"
install -d -m 0700 -o "$REMOTE_USER" -g "$(id -gn "$REMOTE_USER")" \
    /mnt/claude-config /mnt/claude-auth

# CLAUDE_CONFIG_DIR points at the volume; link ~/.claude too so dotfiles
# installers and tools that hard-code ~/.claude land in the same place.
REMOTE_HOME="${_REMOTE_USER_HOME:-$(getent passwd "$REMOTE_USER" | cut -d: -f6)}"
if [ -e "$REMOTE_HOME/.claude" ] || [ -L "$REMOTE_HOME/.claude" ]; then
    echo "claude: $REMOTE_HOME/.claude already exists; not linking it to /mnt/claude-config"
else
    ln -s /mnt/claude-config "$REMOTE_HOME/.claude"
    chown -h "$REMOTE_USER:$(id -gn "$REMOTE_USER")" "$REMOTE_HOME/.claude"
fi
