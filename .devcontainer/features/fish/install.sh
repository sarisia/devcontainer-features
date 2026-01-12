#!/bin/bash

set -euo pipefail

source /etc/os-release

export DEBIAN_FRONTEND=noninteractive

echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${VERSION_ID}/ /" \
    | tee /etc/apt/sources.list.d/shells:fish:release:4.list
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_${VERSION_ID}/Release.key \
    | gpg --dearmor \
    | tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg
apt-get update
apt-get -y --no-install-recommends install fish
