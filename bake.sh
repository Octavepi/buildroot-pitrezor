#!/usr/bin/env bash
# PiTrezor Buildroot build script (renamed from build.sh)

set -Eeuo pipefail
CPU=2

BOLD="$(tput bold 2>/dev/null || true)"
DIM="$(tput dim 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

ok()   { echo -e "✅ ${BOLD}$*${RESET}"; }
info() { echo -e "ℹ️  ${DIM}$*${RESET}"; }
warn() { echo -e "⚠️  ${BOLD}$*${RESET}"; }
err()  { echo -e "❌ ${BOLD}$*${RESET}" >&2; }

cleanup() {
  [[ ${RC:-0} -eq 0 ]] && ok "Bake script finished." || err "Bake script failed."
}
trap 'RC=$?; cleanup' EXIT

if [[ -z "${1:-}" ]]; then
  err "Usage: ./bake.sh <deconfig> [overlay_name] [rotation] [debug]"
  exit 1
fi

DECONFIG="$1"
OVERLAY_NAME="${2:-}"
ROTATION="${3:-}"
MODE="${4:-release}"

ROOT_DIR="$(pwd)"
BR_EXT="${ROOT_DIR}/br-ext"
OUTPUT_DIR="${ROOT_DIR}/output/${DECONFIG}"
BUILDROOT_DIR="${ROOT_DIR}/buildroot"

[[ -d "${BR_EXT}" ]] || { err "Missing br-ext/"; exit 1; }
export BR2_EXTERNAL="${BR_EXT}"

info "Deconfig: ${DECONFIG}"
[[ -n "${OVERLAY_NAME}" ]] && info "Overlay: ${OVERLAY_NAME}"
[[ -n "${ROTATION}" ]] && info "Rotation: ${ROTATION}"
info "Mode: ${MODE}"

if [[ -d .git ]]; then
  git submodule sync --recursive || true
  git submodule update --init --recursive || true
fi

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

DEF_PATH=""
if [[ -f "${BR_EXT}/configs/${DECONFIG}_defconfig" ]]; then
  DEF_PATH="${BR_EXT}/configs/${DECONFIG}_defconfig"
elif [[ -f "configs/${DECONFIG}_defconfig" ]]; then
  DEF_PATH="configs/${DECONFIG}_defconfig"
else
  err "Could not find defconfig '${DECONFIG}_defconfig'"
  exit 1
fi
info "Using defconfig: ${DEF_PATH}"

make -C "${BUILDROOT_DIR}" "${DECONFIG}_defconfig" O="${OUTPUT_DIR}"

# Ensure any global patch directories declared in the config exist, and rewrite to absolute paths
if [[ -f "${OUTPUT_DIR}/.config" ]]; then
  PATCH_DIRS=$(awk -F\" '/^BR2_GLOBAL_PATCH_DIR=/{print $2}' "${OUTPUT_DIR}/.config" || true)
  if [[ -n "${PATCH_DIRS}" ]]; then
    ABS_LIST=""
    for d in ${PATCH_DIRS}; do
      [[ -z "${d}" ]] && continue
      # Resolve relative paths from repo root (not buildroot/)
      if [[ "${d}" = /* ]]; then
        PDIR="${d}"
      else
        PDIR="${ROOT_DIR}/${d}"
      fi
      mkdir -p "${PDIR}"
      info "Ensured patch dir exists: ${PDIR}"
      ABS_LIST+="${PDIR} "
    done
    ABS_LIST=${ABS_LIST%% } # trim trailing space
    if [[ -n "${ABS_LIST}" ]]; then
      sed -i -E "s|^BR2_GLOBAL_PATCH_DIR=.*$|BR2_GLOBAL_PATCH_DIR=\"${ABS_LIST}\"|" "${OUTPUT_DIR}/.config"
      # Refresh config to account for edits
      make -C "${BUILDROOT_DIR}" olddefconfig O="${OUTPUT_DIR}" >/dev/null
    fi
  fi
fi

if [[ -n "${OVERLAY_NAME}" ]]; then
  export PITREZOR_DTO="${OVERLAY_NAME}"
fi
if [[ -n "${ROTATION}" ]]; then
  export PITREZOR_ROT="${ROTATION}"
fi

if [[ "${MODE}" == "debug" ]]; then
  {
    echo 'BR2_ENABLE_DEBUG=y'
    echo 'BR2_STRIP_none=y'
    echo 'BR2_OPTIMIZE_0=y'
  } >> "${OUTPUT_DIR}/.config"
  make -C "${BUILDROOT_DIR}" olddefconfig O="${OUTPUT_DIR}" >/dev/null
fi

make -C "${BUILDROOT_DIR}" -j"${CPU}" O="${OUTPUT_DIR}"

IMAGES_DIR="${OUTPUT_DIR}/images"
if [[ -d "${IMAGES_DIR}" ]]; then
  for c in sdcard.img disk.img; do
    if [[ -f "${IMAGES_DIR}/${c}" && -z "${OVERLAY_NAME}" && -z "${ROTATION}" ]]; then
      BASE_DIR="${ROOT_DIR}/output/base/${DECONFIG}"
      mkdir -p "${BASE_DIR}"
      cp "${IMAGES_DIR}/${c}" "${BASE_DIR}/base-${DECONFIG}.img"
      info "Saved clean base image to: ${BASE_DIR}/base-${DECONFIG}.img"
      break
    fi
  done
fi

ok "Done."
