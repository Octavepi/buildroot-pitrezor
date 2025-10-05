#!/usr/bin/env bash
# PiTrezor Build Script (enhanced)
# Usage: ./build.sh <rpi0|rpi3|rpi4|rpi4-64> <overlay-name> <rotation>
# Example: ./build.sh rpi4-64 waveshare35a 180
# Optional: CLEAN=1 ./build.sh ...

set -euo pipefail

# --- Error trap ---
trap 'echo "❌ Build failed at line $LINENO"; exit 1' ERR

# --- Args ---
if [ $# -lt 3 ]; then
    echo "Usage: $0 <rpi0|rpi3|rpi4|rpi4-64> <overlay-name> <rotation>"
    exit 1
fi

RPI_MODEL="$1"
LCD_OVERLAY="$2"
ROTATION="$3"

case "$RPI_MODEL" in
    rpi0)    DEFCONFIG="pitrezor_rpi0_defconfig" ;;
    rpi3)    DEFCONFIG="pitrezor_rpi3_defconfig" ;;
    rpi4)    DEFCONFIG="pitrezor_rpi4_defconfig" ;;
    rpi4-64) DEFCONFIG="pitrezor_rpi4_64_defconfig" ;;
    *) echo "Invalid model: $RPI_MODEL (valid: rpi0 rpi3 rpi4 rpi4-64)"; exit 1 ;;
esac

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDROOT_DIR="$SCRIPT_DIR/third_party/buildroot"
BR_EXT="$SCRIPT_DIR/br-ext"

# --- Export external trees ---
export BR2_EXTERNAL="$BR_EXT"
export BR2_EXTERNAL_PITREZOR_PATH="$BR_EXT"

# --- Clean if requested ---
if [ "${CLEAN:-0}" -eq 1 ]; then
    echo "🧹 Cleaning buildroot..."
    make -C "$BUILDROOT_DIR" distclean || true
fi

# --- Ensure buildroot exists ---
if [ ! -d "$BUILDROOT_DIR" ]; then
    echo "❌ Buildroot not found at $BUILDROOT_DIR"
    echo "   Try: git submodule update --init --recursive"
    exit 1
fi

# --- Generate br-ext/Config.in (wrappers) ---
cat > "$BR_EXT/Config.in" <<'EOF'
menu "PiTrezor packages"
    source "$BR2_EXTERNAL_PITREZOR_PATH/package/trezord-go/Config.in"
    source "$BR2_EXTERNAL_PITREZOR_PATH/package/fbcp/Config.in"
endmenu
EOF

# --- Build ---
cd "$BUILDROOT_DIR"

echo "🔧 Applying defconfig: $DEFCONFIG"
make BR2_EXTERNAL="$BR_EXT" "$DEFCONFIG"

echo "📦 Building with overlay=$LCD_OVERLAY rotation=$ROTATION"
export LCD_OVERLAY="$LCD_OVERLAY"
export LCD_ROTATION="$ROTATION"

# --- Logging build ---
LOGFILE="$SCRIPT_DIR/build.log"
make BR2_EXTERNAL="$BR_EXT" -j$(nproc) 2>&1 | tee "$LOGFILE"

# --- Results ---
IMAGE="$BUILDROOT_DIR/output/images/sdcard.img"
if [ -f "$IMAGE" ]; then
    echo "✅ Build finished successfully."
    echo "📂 Image: $IMAGE"
    sha256sum "$IMAGE"
else
    echo "❌ Build did not produce sdcard.img"
    exit 1
fi
