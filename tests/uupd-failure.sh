#!/usr/bin/env bash

set -euo pipefail

cd /workspaces/bazzite-updater/tests/failure

cat ./system.txt
sleep 1
cat ./brew.txt
sleep 1
cat ./flatpak.txt
sleep 1
cat ./flatpak-user.txt
sleep 0.2
exit 1