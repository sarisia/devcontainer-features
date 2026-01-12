#!/bin/bash

set -euo pipefail

su ${_REMOTE_USER} -c "mkdir -p /home/${_REMOTE_USER}/.local/share" 2>&1
ln -sf /fish-history /home/${_REMOTE_USER}/.local/share/fish
