#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <deconfig>" >&2
  exit 2
fi

DECONFIG="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BASE_IMG="${ROOT_DIR}/output/base/${DECONFIG}/base-${DECONFIG}.img"

if [[ -f "${BASE_IMG}" ]]; then
  echo "✅ Found base image: ${BASE_IMG}"
  exit 0
else
  echo "❌ Missing base image: ${BASE_IMG}" >&2
  echo "   Build one first (no overlay/rotation): ./bake.sh ${DECONFIG}" >&2
  exit 1
fi
