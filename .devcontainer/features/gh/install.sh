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

if bin="$(find_bin gh)"; then
    echo "gh: already installed at ${bin}; skipping install"
else
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
fi

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

# Install the official gh agent skill from cli/cli, pinned to the gh version we
# just installed so the guidance matches the binary. Falls back to the default
# branch for versions whose tag predates skills/.
# Runs as root: --dir puts the skill in a system path, and the lockfile gh writes
# lands in root's throwaway ~/.agents, never in $_REMOTE_USER's mounted home.
SKILLS="$SHARE/skills"
install -d -m 0755 "$SKILLS"
GH_VERSION="$(gh --version | awk 'NR==1 {print $3}')"
gh skill install cli/cli gh --pin "v${GH_VERSION}" --force --dir "$SKILLS" \
    || gh skill install cli/cli gh --force --dir "$SKILLS"

# Expose the single copy to each agent's system-wide skills dir. Both are
# outside the host mounts the claude/codex features own, so nothing here can
# be adopted onto the host or shadow the host's own skills.
install -d -m 0755 /etc/claude-code/.claude/skills   # Claude Code, managed scope
ln -sfn "$SKILLS/gh" /etc/claude-code/.claude/skills/gh

install -d -m 0755 /etc/codex/skills                 # Codex, admin scope
ln -sfn "$SKILLS/gh" /etc/codex/skills/gh
