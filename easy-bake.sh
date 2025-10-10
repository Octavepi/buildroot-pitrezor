#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: ./easy-bake.sh <deconfig> [overlays] [rotation]"
  exit 1
fi

DECONFIG="$1"
OVERLAYS="${2:-}"
ROTATION="${3:-}"

BASE_DIR="output/${DECONFIG}/base"
OUTPUT_DIR="output/${DECONFIG}/easybake"
IMAGES_DIR="${OUTPUT_DIR}/images"

if [[ ! -d "${BASE_DIR}" ]]; then
  echo "❌ No base image found for ${DECONFIG} in ${BASE_DIR}. Please build one first with ./build.sh ${DECONFIG}."
  exit 1
fi

echo "✅ Found base for ${DECONFIG}."

mkdir -p "${OUTPUT_DIR}"
cp -r "${BASE_DIR}/." "${OUTPUT_DIR}/"

CONFIG_TXT="${IMAGES_DIR}/config.txt"
if [[ -n "${OVERLAYS}" ]]; then
  IFS=',' read -ra DTOS <<< "${OVERLAYS}"
  for dto in "${DTOS[@]}"; do
    echo "dtoverlay=${dto}" >> "${CONFIG_TXT}"
  done
fi

if [[ -n "${ROTATION}" ]]; then
  echo "display_rotate=${ROTATION}" >> "${CONFIG_TXT}"
fi

echo "✅ Easy-bake image ready in ${IMAGES_DIR}"
