#!/usr/bin/env bash

set -euo pipefail

cd /workspaces/bazzite-updater/tests/success

files=(
    "./system.txt"
    "./brew.txt"
    "./flatpak.txt"
    "./flatpak-user.txt"
)

for file in "${files[@]}"; do
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "$line"
        sleep 0.02
    done < "$file"
done