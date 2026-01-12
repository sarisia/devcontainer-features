#!/bin/bash

set -euo pipefail

su ${_REMOTE_USER} -c "curl -fsSL https://claude.ai/install.sh | bash" 2>&1
ln -sf /claude-code/.claude.json /home/${_REMOTE_USER}/.claude.json
