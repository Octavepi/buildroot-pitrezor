#!/usr/bin/env bash
# Easy Bake script: Quickly bake overlays/rotation into base images

set -Eeuo pipefail

if [[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" ]]; then
  echo "Usage: ./easy-bake.sh <deconfig> <overlay_name> <rotation>"
  exit 1
fi

DECONFIG="$1"
OVERLAY_NAME="$2"
ROTATION="$3"

ROOT_DIR="$(pwd)"
BASE_IMG="output/${DECONFIG}/base/base-${DECONFIG}.img"
OUT_DIR="output/${DECONFIG}/easybake"

if [[ ! -f "${BASE_IMG}" ]]; then
  echo "❌ No base image found at ${BASE_IMG}"
  echo "ℹ️  Please run: ./build.sh ${DECONFIG} (with no overlay/rotation args) to generate it first."
  exit 1
fi

mkdir -p "${OUT_DIR}"
NEW_IMG="${OUT_DIR}/easy-${DECONFIG}-${OVERLAY_NAME}-${ROTATION}.img"

echo "ℹ️  Baking overlay=${OVERLAY_NAME}, rotation=${ROTATION} into base..."
cp "${BASE_IMG}" "${NEW_IMG}"

# Append arguments to a metadata file
echo "overlay=${OVERLAY_NAME}" > "${NEW_IMG}.meta"
echo "rotation=${ROTATION}" >> "${NEW_IMG}.meta"

echo "✅ New image at ${NEW_IMG}"
