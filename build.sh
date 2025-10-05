#!/usr/bin/env bash
# PiTrezor Build Script (audited)
# Usage: ./build.sh <rpi0|rpi3|rpi4|rpi4_64> <overlay-name> <rotation>
set -euo pipefail

if [ $# -lt 3 ]; then
  echo "❌ Missing arguments"
  echo "Usage: ./build.sh <rpi0|rpi3|rpi4|rpi4_64> <overlay-name> <rotation>"
  echo "Example: ./build.sh rpi4_64 waveshare35a 180"
  exit 1
fi

PI_MODEL="$1"
LCD_OVERLAY="$2"
ROTATION="$3"

case "$PI_MODEL" in
  rpi0)    DEFCONFIG="pitrezor_rpi0_defconfig" ;;
  rpi3)    DEFCONFIG="pitrezor_rpi3_defconfig" ;;
  rpi4)    DEFCONFIG="pitrezor_rpi4_defconfig" ;;
  rpi4_64) DEFCONFIG="pitrezor_rpi4_64_defconfig" ;;
  *) echo "❌ Unknown Pi model: $PI_MODEL (valid: rpi0|rpi3|rpi4|rpi4_64)"; exit 1;;
esac

# Resolve directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BR_EXT="$SCRIPT_DIR/br-ext"
BUILDROOT_DIR="$SCRIPT_DIR/third_party/buildroot"

# Export external tree (critical: must point at br-ext root)
export BR2_EXTERNAL="$(pwd)/br-ext"

echo "🔍 BR2_EXTERNAL=$BR2_EXTERNAL"
echo "🔍 Buildroot directory=$BUILDROOT_DIR"
echo "🔍 Pi model=$PI_MODEL  | overlay=$LCD_OVERLAY  | rotation=$ROTATION"
echo "🔍 Defconfig=$DEFCONFIG"

# Ensure Buildroot exists
if [ ! -f "$BUILDROOT_DIR/Makefile" ]; then
  echo "❌ Buildroot not found at $BUILDROOT_DIR (is the submodule initialized?)"
  echo "   Try: git submodule update --init --recursive"
  exit 1
fi

# Regenerate br-ext/Config.in with absolute external var (no extra br-ext/ in path)
CONFIG_IN="$BR_EXT/Config.in"
cat > "$CONFIG_IN" <<'EOF'
menu "PiTrezor packages"

endmenu
EOF
echo "✅ Wrote $CONFIG_IN"

# Build
cd "$BUILDROOT_DIR"

# Load selected defconfig (pass BR2_EXTERNAL explicitly)
make BR2_EXTERNAL="$BR_EXT" ${DEFCONFIG}

# Pass overlay/rotation for packages/scripts that consume them
export LCD_OVERLAY="$LCD_OVERLAY"
export LCD_ROTATION="$ROTATION"

# Full build
make BR2_EXTERNAL="$BR_EXT"

echo "🎉 Build finished successfully!"
echo "👉 Image is at: $BUILDROOT_DIR/output/images/sdcard.img"
