#!/bin/bash

set -euo pipefail


su ${_REMOTE_USER} -c "curl -fsSL https://claude.ai/install.sh | bash" 2>&1

# replace ~/.claude with bind mount from host instead
rm -rf /home/${_REMOTE_USER}/.claude
ln -sf /.claude /home/${_REMOTE_USER}
