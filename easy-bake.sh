#!/usr/bin/env bash
# Easy-bake customization for PiTrezor images
#
# Usage: ./easy-bake.sh <deconfig> [overlays] [rotation]
# - <deconfig>: rpi0 | rpi2 | rpi3 | rpi3-64 | rpi4 | rpi4-64
# - overlays: comma-separated dtoverlay list (e.g., waveshare35a,spi0-1cs)
# - rotation: numeric display_rotate (0|90|180|270)

set -Eeuo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: ./easy-bake.sh <deconfig> [overlays] [rotation]"
  exit 1
fi

DECONFIG="$1"
OVERLAYS="${2:-}"
ROTATION="${3:-}"

ROOT_DIR="$(pwd)"
BASE_IMG="${ROOT_DIR}/output/base/${DECONFIG}/base-${DECONFIG}.img"
OUT_DIR="${ROOT_DIR}/output/easybake/${DECONFIG}"
OUT_IMG="${OUT_DIR}/${DECONFIG}-final.img"

if [[ ! -f "${BASE_IMG}" ]]; then
  echo "❌ No base image found: ${BASE_IMG}"
  echo "   Run a clean build first (no overlay/rotation): ./bake.sh ${DECONFIG}"
  exit 1
fi

mkdir -p "${OUT_DIR}"
cp -f "${BASE_IMG}" "${OUT_IMG}"
echo "✅ Copied base image to: ${OUT_IMG}"

# We'll mount the boot (FAT) partition from the image to patch config.txt
MNT=""
LOOPDEV=""

cleanup() {
  set +e
  if mountpoint -q -- "${MNT}"; then sudo umount "${MNT}"; fi
  [[ -n "${MNT}" && -d "${MNT}" ]] && rmdir "${MNT}" 2>/dev/null || true
  if [[ -n "${LOOPDEV}" ]]; then
    # Try partprobe/losetup detach
    sudo losetup -d "${LOOPDEV}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Create loop device with partition scan
LOOPDEV=$(sudo losetup --find --show --partscan "${OUT_IMG}")
if [[ -z "${LOOPDEV}" ]]; then
  echo "❌ Failed to setup loop device"
  exit 1
fi

# Boot partition is p1
BOOT_PART="${LOOPDEV}p1"
if [[ ! -e "${BOOT_PART}" ]]; then
  # Some systems map as /dev/loop0p1, others via kpartx. Try kpartx fallback.
  if command -v kpartx >/dev/null 2>&1; then
    MAP=$(sudo kpartx -as "${OUT_IMG}" | awk 'NR==1{print $3}')
    if [[ -n "${MAP}" && -e "/dev/mapper/${MAP}" ]]; then
      BOOT_PART="/dev/mapper/${MAP}"
    fi
  fi
fi

if [[ ! -e "${BOOT_PART}" ]]; then
  echo "❌ Could not locate boot partition for ${OUT_IMG}"
  exit 1
fi

MNT="$(mktemp -d)"
sudo mount "${BOOT_PART}" "${MNT}"

CONFIG_TXT="${MNT}/config.txt"
if [[ ! -f "${CONFIG_TXT}" ]]; then
  echo "❌ Missing config.txt in boot partition"
  exit 1
fi

# Remove existing lines we'll override to avoid duplicates
sudo sed -i '/^dtoverlay=/d' "${CONFIG_TXT}"
sudo sed -i '/^display_rotate=/d' "${CONFIG_TXT}"

if [[ -n "${OVERLAYS}" ]]; then
  IFS=',' read -r -a DTOS <<< "${OVERLAYS}"
  for dto in "${DTOS[@]}"; do
    [[ -n "${dto}" ]] && echo "dtoverlay=${dto}" | sudo tee -a "${CONFIG_TXT}" >/dev/null
  done
fi

if [[ -n "${ROTATION}" ]]; then
  echo "display_rotate=${ROTATION}" | sudo tee -a "${CONFIG_TXT}" >/dev/null
fi

sync
echo "✅ Updated config.txt in boot partition"
echo "🎯 Final image: ${OUT_IMG}"

