#!/bin/sh
set -e

BOARD_DIR="$(dirname $0)"
IMAGES_DIR="${BINARIES_DIR}"

# Copy boot artefacts expected by genimage
cp -f "${IMAGES_DIR}/Image" "${IMAGES_DIR}/" || true
cp -f "${IMAGES_DIR}/bcm2711-rpi-4-b.dtb" "${IMAGES_DIR}/" || true
mkdir -p "${IMAGES_DIR}/overlays"
cp -r "${IMAGES_DIR}/rpi-firmware/overlays/"* "${IMAGES_DIR}/overlays/" || true
cp -f "${IMAGES_DIR}/rpi-firmware/fixup4.dat" "${IMAGES_DIR}/" || true
cp -f "${IMAGES_DIR}/rpi-firmware/start4.elf" "${IMAGES_DIR}/" || true
cp -f "${BOARD_DIR}/config.txt" "${IMAGES_DIR}/config.txt"
cp -f "${BOARD_DIR}/cmdline.txt" "${IMAGES_DIR}/cmdline.txt"

# Run genimage to produce sdcard.img
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"
mkdir -p "${GENIMAGE_TMP}"

genimage   --rootpath "${TARGET_DIR}"   --tmppath "${GENIMAGE_TMP}"   --inputpath "${IMAGES_DIR}"   --outputpath "${IMAGES_DIR}"   --config "${GENIMAGE_CFG}"

echo "[post-image] sdcard.img generated in ${IMAGES_DIR}"
