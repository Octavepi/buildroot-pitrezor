#!/bin/sh
set -e

BOARD_DIR="$(dirname "$0")"
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

# === Accept driver/rotation args from bake.sh (POSIX-compliant parsing) ===
if [ -n "${PITREZOR_DTO:-}" ]; then
    # POSIX-safe parsing: replace commas with newlines and iterate
    printf '%s\n' "${PITREZOR_DTO}" | tr ',' '\n' | while IFS= read -r dto; do
        [ -n "${dto}" ] && echo "dtoverlay=${dto}" >> "${IMAGES_DIR}/config.txt"
    done
fi
if [ -n "${PITREZOR_ROT:-}" ]; then
    echo "display_rotate=${PITREZOR_ROT}" >> "${IMAGES_DIR}/config.txt"
fi

# === Auto-detect DTB by probing BINARIES_DIR for known Raspberry Pi DTBs ===
DTB=""
for candidate in \
    "bcm2711-rpi-4-b.dtb" \
    "bcm2710-rpi-3-b.dtb" \
    "bcm2709-rpi-2-b.dtb" \
    "bcm2835-rpi-zero.dtb"; do
    if [ -f "${IMAGES_DIR}/${candidate}" ]; then
        DTB="${candidate}"
        break
    fi
done

if [ -z "${DTB}" ]; then
    echo "[post-image] ERROR: No known Raspberry Pi DTB found in ${IMAGES_DIR}" >&2
    echo "[post-image] Looked for: bcm2711-rpi-4-b.dtb, bcm2710-rpi-3-b.dtb, bcm2709-rpi-2-b.dtb, bcm2835-rpi-zero.dtb" >&2
    exit 1
fi

echo "[post-image] Detected DTB: ${DTB}"

# === Auto-select firmware blobs (Pi 4 uses start4/fixup4, others use start/fixup) ===
if [ "${DTB}" = "bcm2711-rpi-4-b.dtb" ]; then
    FIXUP_BLOB="fixup4.dat"
    START_BLOB="start4.elf"
else
    FIXUP_BLOB="fixup.dat"
    START_BLOB="start.elf"
fi

echo "[post-image] Using firmware: ${START_BLOB}, ${FIXUP_BLOB}"

# Generate board-specific genimage.cfg from template with placeholders
GENIMAGE_CFG="${BUILD_DIR}/genimage.cfg"
sed -e "s|__DTB__|${DTB}|g" \
    -e "s|__FIXUP__|${FIXUP_BLOB}|g" \
    -e "s|__START__|${START_BLOB}|g" \
    "${BOARD_DIR}/genimage.cfg.in" > "${GENIMAGE_CFG}"

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"
mkdir -p "${GENIMAGE_TMP}"

# Invoke genimage with clear formatting
genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${IMAGES_DIR}" \
    --outputpath "${IMAGES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo "[post-image] sdcard.img generated in ${IMAGES_DIR}"
