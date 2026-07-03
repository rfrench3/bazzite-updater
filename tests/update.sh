#!/usr/bin/sh
# Simulate real-ish output from commands
# in: exact output, out: already parsed output (not perfect, but more data)

SCRIPT_DIR="$(dirname $0)"

echo "INSTANT TEXT"
sleep 1

echo "INPUT TEXT UUPD 1"
cat "$SCRIPT_DIR/uupd_in_1.txt"

echo "OUTPUT TEXT UUPD 1"
cat "$SCRIPT_DIR/uupd_out_1.txt"

echo "OUTPUT TEXT UUPD 2"
cat "$SCRIPT_DIR/uupd_out_2.txt"
