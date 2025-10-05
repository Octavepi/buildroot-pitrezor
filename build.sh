#!/bin/sh
# PiTrezor Build Script (buildroot)

# Usage: ./build.sh <rpi0|rpi3|rpi4|rpi4-64> <overlay-name> <rotation>
set -eu
set -o pipefail

if [ $# -lt 3 ]; then
  echo "❌ Missing arguments"
  echo "Usage: $0 <rpi0|rpi3|rpi4|rpi4-64> <overlay-name> <rotation>"
  exit 1
fi

PI_MODEL="$1"
LCD_OVERLAY="$2"
ROTATION="$3"

case "$PI_MODEL" in
  rpi0)
    DEFCONFIG="pitrezor_rpi0_defconfig"
    ;;
  rpi3)
    DEFCONFIG="pitrezor_rpi3_defconfig"
    ;;
  rpi4)
    DEFCONFIG="pitrezor_rpi4_defconfig"
    ;;
  rpi4-64)
    DEFCONFIG="pitrezor_rpi4_64_defconfig"
    ;;
  *)
    echo "❌ Invalid model: $PI_MODEL (valid: rpi0 rpi3 rpi4 rpi4-64)"
    exit 1
    ;;
esac

# Resolve directories
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BUILDROOT_DIR="$SCRIPT_DIR/third_party/buildroot"
BR_EXT="$SCRIPT_DIR/br-ext"

# Export external tree
export BR2_EXTERNAL="$BR_EXT"

# Ensure buildroot exists
if [ ! -d "$BUILDROOT_DIR" ]; then
  echo "❌ Buildroot not found at $BUILDROOT_DIR"
  echo "👉 Try: git submodule update --init --recursive"
  exit 1
fi

# Regenerate br-ext/Config.in
cat > "$BR_EXT/Config.in" <<EOF
menu "PiTrezor packages"
    source "$BR_EXT/package/trezord-go/Config.in"
    source "$BR_EXT/package/fbcp/Config.in"
endmenu
EOF

# Build
cd "$BUILDROOT_DIR"

# Apply defconfig and build
make BR2_EXTERNAL="$BR_EXT" "$DEFCONFIG"
make BR2_EXTERNAL="$BR_EXT"

# Pass overlay + rotation into environment
export LCD_OVERLAY="$LCD_OVERLAY"
export LCD_ROTATION="$ROTATION"

echo "✅ Build finished successfully!"

# Image will be here:
echo "👉 Output image: $BUILDROOT_DIR/output/images/sdcard.img"
