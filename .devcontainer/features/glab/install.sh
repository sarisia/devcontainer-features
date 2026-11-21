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

if bin="$(find_bin glab)"; then
    echo "glab: already installed at ${bin}; skipping install"
else
    case "$(dpkg --print-architecture)" in
        amd64)
            glab_arch="amd64"
            ;;
        arm64)
            glab_arch="arm64"
            ;;
        *)
            echo "Unsupported architecture: $(dpkg --print-architecture)" >&2
            exit 1
            ;;
    esac

    release_url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest")"
    version="${release_url##*/}"
    version="${version#v}"
    download_url="https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_${version}_linux_${glab_arch}.tar.gz"

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' EXIT

    curl -fsSL "${download_url}" -o "${tmpdir}/glab.tar.gz"
    tar -xzf "${tmpdir}/glab.tar.gz" -C "${tmpdir}"
    install -m 0755 "${tmpdir}/bin/glab" /usr/local/bin/glab
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
        echo "glab: $dst already exists; not linking it to $1"
        return 0
    fi
    su "$REMOTE_USER" -s /bin/sh -c 'mkdir -p "$(dirname "$1")"' _ "$dst"
    ln -s "$1" "$dst"
    chown -h "$REMOTE_USER:$REMOTE_GROUP" "$dst"
}

install -d -m 0700 -o "$REMOTE_USER" -g "$REMOTE_GROUP" /mnt/glab-config

link_home /mnt/glab-config .config/glab-cli
