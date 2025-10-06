#!/usr/bin/env bash
# PiTrezor build script (patched for RPi stable kernel/headers + hardening)

set -e
set -o pipefail

# Error trap
trap 'echo "❌ Build failed at line $LINENO"; exit 1' ERR

# ---- Args ----
MODEL=$1
if [ -z "$MODEL" ]; then
  echo "Usage: $0 <model>"
  echo "Models: rpi3 rpi4 rpi4-64 clean"
  exit 1
fi

CLEAN=$2

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BR2_EXT_PATH="$SCRIPT_DIR/br-ext"
OUTPUT_DIR="$SCRIPT_DIR/third_party/buildroot/output"

# ---- Clean if requested ----
if [ "$CLEAN" = "clean" ]; then
  echo "🧹 Cleaning build output..."
  rm -rf "$OUTPUT_DIR"
fi

# ---- Deconfig ----
echo "🛠 Applying defconfig for $MODEL..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH" $MODEL"_defconfig"

# ---- Hardening fragment ----
HARDENING_FRAG="$BR2_EXT_PATH/hardening/pitrezor_hardening.fragment"
if [ ! -f "$HARDENING_FRAG" ]; then
  echo "ERROR: Missing $HARDENING_FRAG"
  exit 1
else
echo "✅ Applied hardening fragment"
fi

if [ -x third_party/buildroot/support/kconfig/merge_config.sh ]; then
  third_party/buildroot/support/kconfig/merge_config.sh -m third_party/buildroot/.config "$HARDENING_FRAG"
else

make -C third_party/buildroot olddefconfig BR2_EXTERNAL="$BR2_EXT_PATH"

# ---- Build ----
echo "🚀 Starting build for $MODEL..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH" savedefconfig
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH"

# ---- Output ----
IMAGE_OUTPUT="output/images/sdcard.img"
if [ -f third_party/buildroot/$IMAGE_OUTPUT ]; then
  echo "✅ Build Complete: $SCRIPT_DIR/third_party/buildroot/$IMAGE_OUTPUT"
else
  echo "⚠️ Build finished but no sdcard.img found"
  exit 1
fi

exit 0
