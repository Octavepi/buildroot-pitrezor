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
# Step 1: Auto-generate br-ext/Config.in with all packages
# ------------------------------------------------------------------------------
CONFIG_FILE="br-ext/Config.in"
echo 'menu "External packages"' > $CONFIG_FILE
echo "" >> $CONFIG_FILE

for pkg in br-ext/package/*; do
    if [ -d "$pkg" ] && [ -f "$pkg/Config.in" ]; then
        pkgname=$(basename "$pkg")
        echo "source \"package/$pkgname/Config.in\"" >> $CONFIG_FILE
    fi
done

echo "" >> $CONFIG_FILE
echo "endmenu" >> $CONFIG_FILE

echo "✅ Regenerated $CONFIG_FILE"

# ------------------------------------------------------------------------------
# Step 2: Enter Buildroot and apply defconfig
# ------------------------------------------------------------------------------
cd third_party/buildroot

make BR2_EXTERNAL=../../br-ext pitrezor_${PI_MODEL}_defconfig

# ------------------------------------------------------------------------------
# Step 3: Build
# ------------------------------------------------------------------------------
make

# ------------------------------------------------------------------------------
# Step 4: Post-build overlay tweaks
# ------------------------------------------------------------------------------
cd ../..

# Ensure boot config has LCD overlay & rotation
BOOT_CONFIG="output/images/rpi-firmware/config.txt"
mkdir -p $(dirname $BOOT_CONFIG)

cat <<EOF > $BOOT_CONFIG
dtoverlay=$LCD_OVERLAY
display_rotate=$ROTATION
EOF

echo "✅ Build complete. Image available at output/images/sdcard.img"
