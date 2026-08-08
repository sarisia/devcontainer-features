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

# `gh extension install` above can write a container-local ~/.config/gh/config.yml.
# Discard it before linking -- it's build-time junk, not user data, and if left
# in place it would get adopted onto (or shadow) the host's real config.yml
# once the mount is linked.
su ${_REMOTE_USER} -c 'rm -rf ~/.config/gh'

# The bind mount does not exist at image build time, so linking has to happen at
# runtime; ship the script and let postStartCommand run it.
SHARE=/usr/local/share/gh-feature
install -d -m 0755 "$SHARE"
install -m 0644 "$(dirname "$0")/link-mounts.sh" "$SHARE/link-mounts.sh"
install -m 0755 "$(dirname "$0")/links.sh" "$SHARE/links.sh"

# Feature options are only in the environment during install; persist for postStart.
printf '%s\n' "${EXCLUDE:-}" > "$SHARE/exclude"
chmod 0644 "$SHARE/exclude"
