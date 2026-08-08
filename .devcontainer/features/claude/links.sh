#!/bin/sh

# Mounts owned by this feature; keep in sync with the `mounts` block in
# devcontainer-feature.json. Usage: link <dir|file> <mount> <target under $HOME>

set -eu

. "$(dirname "$0")/link-mounts.sh"

link dir  /mnt/.claude       .claude
link file /mnt/.claude.json  .claude.json
