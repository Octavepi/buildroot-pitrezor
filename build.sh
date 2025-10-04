#!/bin/bash
# Usage: ./build.sh <board> <lcd_overlay> <rotation>
# Example: ./build.sh rpi4 waveshare35a 270

BOARD=${1:-rpi4}
LCD=${2:-waveshare35a}
ROTATE=${3:-270}

echo "Building for board: $BOARD, LCD: $LCD, rotation: $ROTATE"

# Select correct defconfig based on board
case "$BOARD" in
  rpi0)   DEFCONFIG="pitrezor_rpi0_defconfig" ;;
  rpi3)   DEFCONFIG="pitrezor_rpi3_defconfig" ;;
  rpi4)   DEFCONFIG="pitrezor_rpi4_defconfig" ;;
  *)      echo "Unknown board $BOARD"; exit 1 ;;
esac

# Patch config.txt with LCD + rotation
CONFIG_FILE="br-ext/board/pitrezor/config.txt"
if [ -f "$CONFIG_FILE" ]; then
  sed -i "s|^dtoverlay=.*|dtoverlay=${LCD},rotate=${ROTATE},speed=62000000,fps=60|" $CONFIG_FILE
else
  echo "dtoverlay=${LCD},rotate=${ROTATE},speed=62000000,fps=60" >> $CONFIG_FILE
fi

# Run Buildroot with the selected defconfig
make -C third_party/buildroot BR2_EXTERNAL=../../br-ext ${DEFCONFIG}
make -C third_party/buildroot
