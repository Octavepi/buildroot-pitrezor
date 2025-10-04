#!/bin/sh
set -e
ROOT="$1"

# Ensure trezor home and firmware path exist with correct ownership
mkdir -p "${ROOT}/home/trezor"
chown -R trezor:trezor "${ROOT}/home/trezor" || true
if [ -d "${ROOT}/opt/trezor-firmware" ]; then
  chown -R trezor:trezor "${ROOT}/opt/trezor-firmware"
fi
