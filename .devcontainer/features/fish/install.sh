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
    . /etc/os-release

    case "${ID}" in
        debian)
            repo="http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${VERSION_ID}"
            key_url="https://download.opensuse.org/repositories/shells:fish:release:4/Debian_${VERSION_ID}/Release.key"

            echo "deb [signed-by=/etc/apt/trusted.gpg.d/shells_fish_release_4.gpg] ${repo}/ /" \
                > /etc/apt/sources.list.d/shells:fish:release:4.list
            curl -fsSL "${key_url}" | gpg --dearmor \
                > /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg
            ;;
        ubuntu)
            curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x88421E703EDC7AF54967DED473C9FCC9E2BB48DA" \
                | gpg --dearmor > /etc/apt/trusted.gpg.d/fish_release_4.gpg
            echo "deb [signed-by=/etc/apt/trusted.gpg.d/fish_release_4.gpg] https://ppa.launchpadcontent.net/fish-shell/release-4/ubuntu ${VERSION_CODENAME} main" \
                > /etc/apt/sources.list.d/fish-shell-release-4.list
            ;;
        *)
            echo "Unsupported OS: ${ID}" >&2
            exit 1
            ;;
    esac

    apt-get update
    apt-get install -y fish
fi

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'mkdir -p ~/.local/share/fish && ln -sf /mnt/fish-shell-history/fish_history ~/.local/share/fish/fish_history'
