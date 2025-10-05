#!/bin/bash
set -e

# Arguments
PI_MODEL=$1
LCD_OVERLAY=$2
ROTATION=$3

if [ -z "$PI_MODEL" ] || [ -z "$LCD_OVERLAY" ] || [ -z "$ROTATION" ]; then
    echo "Usage: $0 <pi-model> <overlay-name> <rotation>"
    echo "Example: $0 rpi4 waveshare35a 180"
    exit 1
fi

# ------------------------------------------------------------------------------
# Step 1: Resolve absolute paths
# ------------------------------------------------------------------------------
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
BR_EXT="$REPO_ROOT/br-ext"
BUILDROOT_DIR="$REPO_ROOT/third_party/buildroot"

echo "🔍 Using BR2_EXTERNAL=$BR_EXT"
echo "🔍 Buildroot directory=$BUILDROOT_DIR"

# ------------------------------------------------------------------------------
# Step 2: Auto-generate br-ext/Config.in with all packages
# ------------------------------------------------------------------------------
CONFIG_FILE="$BR_EXT/Config.in"
echo 'menu "External packages"' > $CONFIG_FILE
echo "" >> $CONFIG_FILE

for pkg in $BR_EXT/package/*; do
    if [ -d "$pkg" ] && [ -f "$pkg/Config.in" ]; then
        pkgname=$(basename "$pkg")
        echo "source \"package/$pkgname/Config.in\"" >> $CONFIG_FILE
    fi
done

echo "" >> $CONFIG_FILE
echo "endmenu" >> $CONFIG_FILE

echo "✅ Regenerated $CONFIG_FILE"

# ------------------------------------------------------------------------------
# Step 3: Enter Buildroot and apply defconfig
# ------------------------------------------------------------------------------
cd $BUILDROOT_DIR
make BR2_EXTERNAL=$BR_EXT pitrezor_${PI_MODEL}_defconfig

# ------------------------------------------------------------------------------
# Step 4: Build
# ------------------------------------------------------------------------------
make

# ------------------------------------------------------------------------------
# Step 5: Post-build overlay tweaks
# ------------------------------------------------------------------------------
cd $REPO_ROOT

BOOT_CONFIG="output/images/rpi-firmware/config.txt"
mkdir -p $(dirname $BOOT_CONFIG)

cat <<EOF > $BOOT_CONFIG
dtoverlay=$LCD_OVERLAY
display_rotate=$ROTATION
EOF

echo "✅ Build complete. Image available at output/images/sdcard.img"
