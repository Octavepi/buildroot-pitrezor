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

# === Select DTB based on DECONFIG ===
case "${DECONFIG}" in
  rpi4-64|rpi4)
    DTB="bcm2711-rpi-4-b.dtb"
    ;;
  rpi3-64|rpi3)
    DTB="bcm2710-rpi-3-b.dtb"
    ;;
  rpi2)
    DTB="bcm2709-rpi-2-b.dtb"
    ;;
  rpi0)
    DTB="bcm2835-rpi-zero.dtb"
    ;;
  *)
    echo "[post-image] Unknown board: ${DECONFIG}" >&2
    exit 1
    ;;
esac

# Generate board-specific genimage.cfg from template
GENIMAGE_CFG="${BUILD_DIR}/genimage.cfg"
sed "s|__DTB__|${DTB}|g" "${BOARD_DIR}/genimage.cfg.in" > "${GENIMAGE_CFG}"

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"
mkdir -p "${GENIMAGE_TMP}"

genimage \    --rootpath "${TARGET_DIR}" \    --tmppath "${GENIMAGE_TMP}" \    --inputpath "${IMAGES_DIR}" \    --outputpath "${IMAGES_DIR}" \    --config "${GENIMAGE_CFG}"

echo "[post-image] sdcard.img generated in ${IMAGES_DIR}"
