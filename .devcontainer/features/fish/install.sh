#!/bin/bash

set -euo pipefail

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

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'mkdir -p ~/.local/share/fish && ln -sf /mnt/fish-shell-history/fish_history ~/.local/share/fish/fish_history'
