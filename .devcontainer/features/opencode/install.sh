#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "npm i -g opencode-ai" 2>&1

# The bind mounts do not exist at image build time, so linking has to happen at
# runtime; ship the script and let postStartCommand run it.
SHARE=/usr/local/share/opencode-feature
install -d -m 0755 "$SHARE"
install -m 0644 "$(dirname "$0")/link-mounts.sh" "$SHARE/link-mounts.sh"
install -m 0755 "$(dirname "$0")/links.sh" "$SHARE/links.sh"

# Feature options are only in the environment during install; persist for postStart.
printf '%s\n' "${EXCLUDE:-}" > "$SHARE/exclude"
chmod 0644 "$SHARE/exclude"
