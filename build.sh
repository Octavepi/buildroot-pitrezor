#!/usr/bin/env bash
# PiTrezor Build Script (patched for Raspberry Pi stable kernel/headers)

set -e
set -o pipefail

# Error trap
trap 'echo "❌ Build failed at line $LINENO"; exit 1' ERR

# ---- Args ----
MODEL=$1
if [ -z "$MODEL" ]; then
    echo "Usage: $0 <rpi3|rpi3_64|rpi4|rpi4_64> [clean]"
    exit 1
fi

CLEAN=$2

# ---- Paths ----
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export BR2_EXTERNAL_PITREZOR_PATH="$SCRIPT_DIR/br-ext"

# ---- Clean if requested ----
if [ "$CLEAN" == "clean" ]; then
    echo "🧹 Cleaning build output..."
    rm -rf "$SCRIPT_DIR/third_party/buildroot/output"
fi

# ---- Defconfig ----
echo "⚙️  Applying defconfig for $MODEL..."
DEFCONFIG="configs/${MODEL}_defconfig"
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXTERNAL_PITREZOR_PATH" "$DEFCONFIG"

# ---- Stable Kernel + Headers ----
# Always pull latest stable Raspberry Pi kernel branch
cat >> third_party/buildroot/.config <<'EOF'

# Kernel settings
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_GIT=y
BR2_LINUX_KERNEL_CUSTOM_REPO_URL="https://github.com/raspberrypi/linux.git"
BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION="stable"

# Headers should always match kernel
BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM=y
BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_STABLE=y

EOF

# Save new config
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXTERNAL_PITREZOR_PATH" olddefconfig

# ---- Build ----
echo "🚀 Starting build for $MODEL..."
make -C third_party/buildroot BR2_EXTERNAL="$BR2_EXTERNAL_PITREZOR_PATH" -j$(nproc)

# ---- Output ----
IMAGE=output/images/sdcard.img
if [ -f "third_party/buildroot/$IMAGE" ]; then
    echo "✅ Build complete: third_party/buildroot/$IMAGE"
else
    echo "⚠️ Build finished but no sdcard.img found"
    exit 1
fi

exit 0
