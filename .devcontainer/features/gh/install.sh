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

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'mkdir -p ~/.config && rm -rf ~/.config/gh && ln -sf /mnt/gh ~/.config/gh'
