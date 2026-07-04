#!/bin/sh
# SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# This script runs a systemd service similarly to a normal program.
# Start journalctl   ->   systemctl start --wait   ->   kill journalctl

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE_NAME="$1"

journalctl -u "$SERVICE_NAME" -f --lines=0 -o cat --synchronize-on-exit=yes &
JOURNAL_PID=$!

trap 'kill -TERM $JOURNAL_PID 2>/dev/null' EXIT

systemctl start --wait "$SERVICE_NAME"
