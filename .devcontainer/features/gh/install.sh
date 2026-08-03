#!/bin/bash

set -euo pipefail

# Install via the official GitHub CLI apt repository
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian
apt-get update
apt-get install -y curl gpg

mkdir -p -m 755 /etc/apt/keyrings
out="$(mktemp)"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "${out}"
cat "${out}" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

mkdir -p -m 755 /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

apt-get update
apt-get install -y gh

# symlink in install.sh to avoid conflicting with the mount in devcontainer.json
su ${_REMOTE_USER} -c 'mkdir -p ~/.config && rm -rf ~/.config/gh && ln -sf /mnt/gh ~/.config/gh'

# Install gh extensions
# - not passed: JSON default provides "github/gh-stack"
# - empty string: install nothing (dash form keeps empty as empty)
EXTENSIONS="${EXTENSIONS-github/gh-stack}"
IFS=',' read -ra _exts <<< "${EXTENSIONS}"
for ext in "${_exts[@]}"; do
    ext="$(echo "${ext}" | xargs)"   # trim surrounding whitespace
    [ -z "${ext}" ] && continue
    su ${_REMOTE_USER} -c "gh extension install '${ext}'"
done
