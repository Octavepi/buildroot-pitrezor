#!/usr/bin/env bash
# PiTrezor build script (patched for RPi stable kernel/headers + hardening/debug)

set -e
set -o pipefail

trap 'echo "❌ Build failed at line $LINENO"; exit 1' ERR

# ---- Args ----
MODEL=$1
MODE=$2   # optional: "debug" or default (hardened)

if [ -z "$MODEL" ]; then
  echo "Usage: $0 <model> [mode]"
  echo "Models: rpi3 rpi4 rpi4-64"
  echo "Modes:  (default) | debug"
  exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BR2_EXT_PATH="$SCRIPT_DIR/br-ext"
OUTPUT_DIR="$SCRIPT_DIR/third_party/buildroot/output"

# ---- Deconfig ----
echo "📦 Applying deconfig for $MODEL..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH" ${MODEL}_defconfig

# ---- Hardening/Debug fragment ----
if [ "$MODE" = "debug" ]; then
  FRAGMENT="$BR2_EXT_PATH/hardening/pitrezor_debug.fragment"
else
  FRAGMENT="$BR2_EXT_PATH/hardening/pitrezor_hardening.fragment"
fi

if [ ! -f "$FRAGMENT" ]; then
  echo "ERROR: Missing fragment $FRAGMENT"
  exit 1
fi

echo "🔐 Applying fragment: $(basename $FRAGMENT)"
if ! third_party/buildroot/support/kconfig/merge_config.sh \
      third_party/buildroot/.config "$FRAGMENT"; then
  echo "ERROR: merge_config.sh failed"
  exit 1
fi

# ---- Build ----
echo "🚀 Starting build for $MODEL ($MODE)..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH"

# ---- Output ----
IMAGE_OUTPUT="output/images/sdcard.img"
if [ -f "third_party/buildroot/$IMAGE_OUTPUT" ]; then
  echo "✅ Build Complete: $SCRIPT_DIR/third_party/buildroot/$IMAGE_OUTPUT"
else
  echo "⚠️ Build finished but no sdcard.img found"
  exit 1
fi
