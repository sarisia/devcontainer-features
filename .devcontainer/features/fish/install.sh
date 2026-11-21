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

if bin="$(find_bin fish)"; then
    echo "fish: already installed at ${bin}; skipping install"
else
    # Static build from GitHub releases: a single self-contained binary, so no
    # distro repo (OBS mirrors are too flaky) and no per-distro branching.
    case "$(uname -m)" in
        x86_64)        arch=x86_64 ;;
        aarch64|arm64) arch=aarch64 ;;
        *) echo "fish: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac

    if ! command -v curl >/dev/null || ! command -v xz >/dev/null; then
        apt-get update
        apt-get install -y --no-install-recommends ca-certificates curl xz-utils
    fi

    FISH_VERSION="${VERSION:-latest}"
    if [ "$FISH_VERSION" = latest ]; then
        FISH_VERSION="$(basename "$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
            https://github.com/fish-shell/fish-shell/releases/latest)")"
    fi

    curl -fsSL "https://github.com/fish-shell/fish-shell/releases/download/${FISH_VERSION}/fish-${FISH_VERSION}-linux-${arch}.tar.xz" \
        | tar -xJ -C /usr/local/bin fish
    chmod 0755 /usr/local/bin/fish
    grep -qx /usr/local/bin/fish /etc/shells || echo /usr/local/bin/fish >> /etc/shells
fi

# A fresh named volume copies the ownership of its image mount point, so this
# hands the volume to the remote user without a runtime chown.
REMOTE_USER="${_REMOTE_USER:-root}"
REMOTE_GROUP="$(id -gn "$REMOTE_USER")"
REMOTE_HOME="${_REMOTE_USER_HOME:-$(getent passwd "$REMOTE_USER" | cut -d: -f6)}"
install -d -m 0755 -o "$REMOTE_USER" -g "$REMOTE_GROUP" /mnt/fish-shell-history

# Dangling until fish first saves history; fish resolves the link and writes
# through it into the volume.
HIST="$REMOTE_HOME/.local/share/fish/fish_history"
if [ -e "$HIST" ] && [ ! -L "$HIST" ]; then
    echo "fish: $HIST already exists; not linking it to /mnt/fish-shell-history"
else
    su "$REMOTE_USER" -s /bin/sh -c 'mkdir -p "$(dirname "$1")"' _ "$HIST"
    ln -sfn /mnt/fish-shell-history/fish_history "$HIST"
    chown -h "$REMOTE_USER:$REMOTE_GROUP" "$HIST"
fi
