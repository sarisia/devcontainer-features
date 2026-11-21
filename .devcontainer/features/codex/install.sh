#!/bin/bash

set -euo pipefail

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

if bin="$(find_bin codex)"; then
    echo "codex: already installed at ${bin}; skipping install"
else
    su ${_REMOTE_USER} -c "npm i -g @openai/codex" 2>&1
fi

# A fresh named volume copies the ownership and contents of its image mount
# point, so this hands the volumes to the remote user without a runtime chown.
REMOTE_USER="${_REMOTE_USER:-root}"
REMOTE_GROUP="$(id -gn "$REMOTE_USER")"
REMOTE_HOME="${_REMOTE_USER_HOME:-$(getent passwd "$REMOTE_USER" | cut -d: -f6)}"

# Point $2 under the remote user's home at volume $1, so tools and dotfiles
# installers that hard-code the home path land in the volume.
link_home() {
    dst="$REMOTE_HOME/$2"
    [ "$(readlink "$dst" 2>/dev/null)" = "$1" ] && return 0
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "codex: $dst already exists; not linking it to $1"
        return 0
    fi
    su "$REMOTE_USER" -s /bin/sh -c 'mkdir -p "$(dirname "$1")"' _ "$dst"
    ln -s "$1" "$dst"
    chown -h "$REMOTE_USER:$REMOTE_GROUP" "$dst"
}

install -d -m 0700 -o "$REMOTE_USER" -g "$REMOTE_GROUP" /mnt/codex-home /mnt/codex-auth
install -d -m 0755 -o "$REMOTE_USER" -g "$REMOTE_GROUP" /mnt/agents

# Codex opens auth.json without O_NOFOLLOW, so a login writes through this link
# into the volume every container shares.
ln -sfn /mnt/codex-auth/auth.json /mnt/codex-home/auth.json
chown -h "$REMOTE_USER:$REMOTE_GROUP" /mnt/codex-home/auth.json

link_home /mnt/codex-home .codex
link_home /mnt/agents .agents
