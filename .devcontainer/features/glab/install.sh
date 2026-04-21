#!/bin/bash

set -euo pipefail

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

# remove ~/.config/glab-cli and use bind mount from host instead
rm -rf "/home/${_REMOTE_USER}/.config/glab-cli"
su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.config" 2>&1
ln -sf /glab-cli "/home/${_REMOTE_USER}/.config/glab-cli"
