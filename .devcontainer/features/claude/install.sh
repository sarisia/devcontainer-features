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

# The bind mounts do not exist at image build time, so linking has to happen at
# runtime; ship the script and let postStartCommand run it.
SHARE=/usr/local/share/claude-feature
install -d -m 0755 "$SHARE"
install -m 0644 "$(dirname "$0")/link-mounts.sh" "$SHARE/link-mounts.sh"
install -m 0755 "$(dirname "$0")/links.sh" "$SHARE/links.sh"

# Feature options are only in the environment during install; persist for postStart.
printf '%s\n' "${EXCLUDE:-}" > "$SHARE/exclude"
chmod 0644 "$SHARE/exclude"
