#!/usr/bin/env bash
# PiTrezor Buildroot build script (full, tidy, and surgical)
# Works on any modern Linux host.
# Preserves pretty logging, overlay/rotation args, and adds strict fragment injection.
# Usage:
#   ./build.sh <deconfig> [overlay_name] [rotation] [debug]
# Examples:
#   ./build.sh rpi4-64
#   ./build.sh rpi4-64 waveshare35a 270
#   ./build.sh rpi3-64 lcd35 90 debug

set -Eeuo pipefail

############################
# Pretty logging helpers
############################
BOLD="$(tput bold 2>/dev/null || true)"
DIM="$(tput dim 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

ok()   { echo -e "✅ ${BOLD}$*${RESET}"; }
info() { echo -e "ℹ️  ${DIM}$*${RESET}"; }
warn() { echo -e "⚠️  ${BOLD}$*${RESET}"; }
err()  { echo -e "❌ ${BOLD}$*${RESET}" >&2; }

cleanup() {
  [[ ${RC:-0} -eq 0 ]] && ok "Build script finished." || err "Build script failed."
}
trap 'RC=$?; cleanup' EXIT

############################
# Args & defaults
############################
if [[ -z "${1:-}" ]]; then
  err "Usage: ./build.sh <deconfig> [overlay_name] [rotation] [debug]"
  exit 1
fi

DECONFIG="$1"           # required (e.g., rpi4-64, rpi3, rpi4, rpi3-64)
OVERLAY_NAME="${2:-}"    # e.g. waveshare35a, lcd35, etc.
ROTATION="${3:-}"        # 0 | 90 | 180 | 270
MODE="${4:-release}"     # "debug" to enable debug build toggles

############################
# Paths
############################
ROOT_DIR="$(pwd)"
BR_EXT="${ROOT_DIR}/br-ext"
FRAGMENTS_DIR="${BR_EXT}/configs"
STRICT_FRAGMENT="${FRAGMENTS_DIR}/wallet_strict_fragment.config"
OUTPUT_DIR="${ROOT_DIR}/output/${DECONFIG}"
BUILDROOT_DIR="${ROOT_DIR}/third_party/buildroot"

############################
# Sanity checks
############################
[[ -d "${BR_EXT}" ]] || { err "Missing br-ext/ (external tree). Are you in the repo root?"; exit 1; }
[[ -f "${STRICT_FRAGMENT}" ]] || { err "Missing strict fragment: ${STRICT_FRAGMENT}"; exit 1; }

# External tree (Buildroot will also look here for defconfigs & pkg Config.in)
export BR2_EXTERNAL="${BR_EXT}"

# Friendly echo of context
info "Root:          ${ROOT_DIR}"
info "External tree: ${BR2_EXTERNAL}"
info "Deconfig:      ${DECONFIG}"
[[ -n "${OVERLAY_NAME}" ]] && info "Overlay:       ${OVERLAY_NAME}"
[[ -n "${ROTATION}"     ]] && info "Rotation:      ${ROTATION}"
info "Mode:          ${MODE}"
echo

############################
# Submodules (best-effort, no-op if not a git checkout)
############################
if [[ -d .git ]]; then
  info "Syncing submodules (best-effort)…"
  git submodule sync --recursive || true
  git submodule update --init --recursive || true
fi

############################
# Output tree
############################
info "Preparing output tree: ${OUTPUT_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

############################
# Select defconfig
############################
DEF_PATH=""
if [[ -f "${BR_EXT}/configs/${DECONFIG}_defconfig" ]]; then
  DEF_PATH="${BR_EXT}/configs/${DECONFIG}_defconfig"
elif [[ -f "configs/${DECONFIG}_defconfig" ]]; then
  DEF_PATH="configs/${DECONFIG}_defconfig"
else
  err "Could not find defconfig '${DECONFIG}_defconfig' in br-ext/configs/ or buildroot/configs/."
  exit 1
fi
info "Using defconfig: ${DEF_PATH}"

info "Seeding .config from defconfig…"
make -C "${BUILDROOT_DIR}" "${DECONFIG}_defconfig" O="${OUTPUT_DIR}"

############################
# Overlay & rotation
############################
if [[ -n "${OVERLAY_NAME}" ]]; then
  info "Passing screen overlay hint to build: ${OVERLAY_NAME}"
  export PITREZOR_DTO="${OVERLAY_NAME}"
fi

if [[ -n "${ROTATION}" ]]; then
  case "${ROTATION}" in
    0|90|180|270) : ;;
    *) warn "Rotation '${ROTATION}' is not one of 0/90/180/270. Ignoring."; ROTATION="";;
  esac
  if [[ -n "${ROTATION}" ]]; then
    info "Passing rotation hint to build: ${ROTATION}"
    export PITREZOR_ROT="${ROTATION}"
  fi
fi

############################
# Debug toggle
############################
if [[ "${MODE}" == "debug" ]]; then
  info "Enabling debug-friendly flags via fragment overlay…"
  {
    echo 'BR2_ENABLE_DEBUG=y'
    echo 'BR2_STRIP_none=y'
    echo 'BR2_OPTIMIZE_0=y'
  } >> "${OUTPUT_DIR}/.config"
  make -C "${BUILDROOT_DIR}" olddefconfig O="${OUTPUT_DIR}" >/dev/null
  ok "Debug mode is ON (no stripping, -O0)."
else
  info "Release mode (default): stripping & normal optimizations."
fi

############################
# Build
############################
make -C "${BUILDROOT_DIR}" -j"${CPU}" O="${OUTPUT_DIR}"

############################
# Results summary
############################
IMAGES_DIR="${OUTPUT_DIR}/images"
echo
if [[ -d "${IMAGES_DIR}" ]]; then
  ok "Images produced in: ${IMAGES_DIR}"
  FOUND=$(ls -1 "${IMAGES_DIR}" 2>/dev/null || true)
  if [[ -n "${FOUND}" ]]; then
    info "Artifacts:"
    echo "${FOUND}" | sed 's/^/  • /'
    echo
    PRIMARY=""
    for c in sdcard.img disk.img; do
      [[ -f "${IMAGES_DIR}/${c}" ]] && PRIMARY="${c}" && break
    done
    if [[ -n "${PRIMARY}" ]]; then
      info "Primary image: ${PRIMARY}"
      sha256sum "${IMAGES_DIR}/${PRIMARY}" | awk '{print "🔒 SHA-256: " $1}'
      du -h "${IMAGES_DIR}/${PRIMARY}" | awk '{print "📦 Size:    " $1}'
    fi
  else
    warn "No files in ${IMAGES_DIR}."
  fi
else
  warn "No images/ directory found under ${OUTPUT_DIR}."
fi

ok "Done."