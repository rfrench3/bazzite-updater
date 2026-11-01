#!/usr/bin/env bash

set -euo pipefail

cd /workspaces/bazzite-updater/tests

while IFS= read -r line || [[ -n "$line" ]]; do
    echo "$line"
    sleep 0.05
done < "./uupd-failure.txt"
