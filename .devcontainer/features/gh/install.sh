#!/bin/bash

set -euo pipefail

case "$(dpkg --print-architecture)" in
    amd64)
        gh_arch="amd64"
        ;;
    arm64)
        gh_arch="arm64"
        ;;
    *)
        echo "Unsupported architecture: $(dpkg --print-architecture)" >&2
        exit 1
        ;;
esac

release_url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/cli/cli/releases/latest")"
version="${release_url##*/}"
version="${version#v}"
download_url="https://github.com/cli/cli/releases/latest/download/gh_${version}_linux_${gh_arch}.tar.gz"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

curl -fsSL "${download_url}" -o "${tmpdir}/gh.tar.gz"
tar -xzf "${tmpdir}/gh.tar.gz" -C "${tmpdir}"
install -m 0755 "${tmpdir}/gh_${version}_linux_${gh_arch}/bin/gh" /usr/local/bin/gh

# remove ~/.config/gh and use bind mount from host instead
rm -rf "/home/${_REMOTE_USER}/.config/gh"
su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.config" 2>&1
ln -sf /gh "/home/${_REMOTE_USER}/.config/gh"
