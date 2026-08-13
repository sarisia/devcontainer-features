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

# The bind mount does not exist at image build time, so linking has to happen at
# runtime; ship the script and let postStartCommand run it.
SHARE=/usr/local/share/glab-feature
install -d -m 0755 "$SHARE"
install -m 0644 "$(dirname "$0")/link-mounts.sh" "$SHARE/link-mounts.sh"
install -m 0755 "$(dirname "$0")/links.sh" "$SHARE/links.sh"

# Feature options are only in the environment during install; persist for postStart.
printf '%s\n' "${EXCLUDE:-}" > "$SHARE/exclude"
chmod 0644 "$SHARE/exclude"
