#!/bin/sh
set -e

BOARD_DIR="$(dirname $0)"
IMAGES_DIR="${BINARIES_DIR}"

# Copy boot artefacts expected by genimage
cp -f "${IMAGES_DIR}/Image" "${IMAGES_DIR}/" || true
cp -f "${IMAGES_DIR}"/*.dtb "${IMAGES_DIR}/" || true
mkdir -p "${IMAGES_DIR}/overlays"
cp -r "${IMAGES_DIR}/rpi-firmware/overlays/"* "${IMAGES_DIR}/overlays/" || true
cp -f "${IMAGES_DIR}/rpi-firmware/"*.dat "${IMAGES_DIR}/" || true
cp -f "${IMAGES_DIR}/rpi-firmware/"*.elf "${IMAGES_DIR}/" || true

cp -f "${BOARD_DIR}/config.txt" "${IMAGES_DIR}/config.txt"
cp -f "${BOARD_DIR}/cmdline.txt" "${IMAGES_DIR}/cmdline.txt"

# === Accept driver/rotation args from build.sh (aligned vars) ===
if [ -n "${PITREZOR_DTO:-}" ]; then
    echo "dtoverlay=${PITREZOR_DTO}" >> "${IMAGES_DIR}/config.txt"
fi
if [ -n "${PITREZOR_ROT:-}" ]; then
    echo "display_rotate=${PITREZOR_ROT}" >> "${IMAGES_DIR}/config.txt"
fi

# === Prepare persistent calibration + config target ===
mkdir -p "${TARGET_DIR}/data/tslib"

: > "${TARGET_DIR}/data/tslib/ts.cal"
chmod 644 "${TARGET_DIR}/data/tslib/ts.cal"

if [ ! -f "${TARGET_DIR}/data/tslib/ts.conf" ]; then
    cp "${BOARD_DIR}/ts.conf" "${TARGET_DIR}/data/tslib/ts.conf"
fi
chmod 644 "${TARGET_DIR}/data/tslib/ts.conf"

GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"
mkdir -p "${GENIMAGE_TMP}"

genimage \    --rootpath "${TARGET_DIR}" \    --tmppath "${GENIMAGE_TMP}" \    --inputpath "${IMAGES_DIR}" \    --outputpath "${IMAGES_DIR}" \    --config "${GENIMAGE_CFG}"

echo "[post-image] sdcard.img generated in ${IMAGES_DIR}"
