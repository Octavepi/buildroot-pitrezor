#!/usr/bin/env bash
# PiTrezor build script (patched for RPi stable kernel/headers)

set -e
set -o pipefail

# Error trap
trap 'echo "❌ Build failed at line $LINENO"; exit 1' ERR

# ---- Args ----
MODEL=$1
if [ -z "$MODEL" ]; then
  echo "Usage: $0 <model>"
  echo "Models: rpi3 rpi4 rpi464 clean"
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
echo "📐 Applying defconfig for $MODEL..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXT_PATH" "${MODEL}_defconfig"

# ---- Kernel (stable branch) ----
cat >> third_party/buildroot/.config <<EOF

# Track Raspberry Pi kernel (stable branch)
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_TARBALL=y
BR2_LINUX_KERNEL_CUSTOM_REPO_URL="https://github.com/raspberrypi/linux.git"
BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION="stable"

# Match headers against stable kernel
BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_6_1=y
EOF

# ---- Build ----
echo "🔨 Starting build for $MODEL..."
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
