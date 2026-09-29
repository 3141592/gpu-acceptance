#!/usr/bin/env bash
set -euo pipefail

SINCE="${1:-}"

echo "=== NVIDIA KERNEL ERROR CHECK ==="

if [[ -n "$SINCE" ]]; then
    echo "Checking kernel journal since: $SINCE"
    JOURNAL=(journalctl -k --since "$SINCE" --no-pager)
else
    echo "Checking entire available kernel journal"
    JOURNAL=(journalctl -k --no-pager)
fi

OUTPUT="$(
    "${JOURNAL[@]}" \
        | grep -iE 'NVRM: Xid|NVRM: GPU.*fallen off|nvidia.*Xid' \
        || true
)"

if [[ -n "$OUTPUT" ]]; then
    echo
    echo "$OUTPUT"
    echo
    echo "FAIL: NVIDIA kernel errors were found."
    exit 2
fi

echo
echo "PASS: no NVIDIA Xid or GPU-fallen-off errors found."
