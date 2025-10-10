#!/usr/bin/env bash
# PiTrezor Buildroot build script (renamed from build.sh)

set -Eeuo pipefail
# Parallelism: use all cores by default; allow override via env CPU
CPU="${CPU:-$(nproc 2>/dev/null || echo 2)}"

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

# Prefer kernel tarball download over git clone (faster, fewer network issues)
# Override by setting USE_GIT=1 in the environment.
if [[ -f "${OUTPUT_DIR}/.config" && "${USE_GIT:-0}" != "1" ]]; then
  K_REPO=$(awk -F\" '/^BR2_LINUX_KERNEL_CUSTOM_REPO_URL=/{print $2}' "${OUTPUT_DIR}/.config" || true)
  K_VER=$(awk -F\" '/^BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION=/{print $2}' "${OUTPUT_DIR}/.config" || true)
  if [[ -n "${K_REPO}" && -n "${K_VER}" && "${K_REPO}" == https://github.com/*/*.git ]]; then
    BASE_URL="${K_REPO%.git}"
    # Heuristics for archive path
    if [[ "${K_VER}" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
      TARBALL_URL="${BASE_URL}/archive/${K_VER}.tar.gz"
    elif [[ "${K_VER}" =~ ^v?[0-9].* ]]; then
      TARBALL_URL="${BASE_URL}/archive/refs/tags/${K_VER}.tar.gz"
    else
      TARBALL_URL="${BASE_URL}/archive/refs/heads/${K_VER}.tar.gz"
    fi
    info "Switching kernel source to tarball: ${TARBALL_URL} (set USE_GIT=1 to keep git)"
    # Disable custom git and enable custom tarball with location
    if grep -q '^BR2_LINUX_KERNEL_CUSTOM_GIT=y' "${OUTPUT_DIR}/.config"; then
      sed -i -E 's/^BR2_LINUX_KERNEL_CUSTOM_GIT=y/# BR2_LINUX_KERNEL_CUSTOM_GIT is not set/' "${OUTPUT_DIR}/.config"
    fi
    # Ensure boolean is enabled
    if grep -q '^# BR2_LINUX_KERNEL_CUSTOM_TARBALL is not set' "${OUTPUT_DIR}/.config"; then
      sed -i -E 's/^# BR2_LINUX_KERNEL_CUSTOM_TARBALL is not set/BR2_LINUX_KERNEL_CUSTOM_TARBALL=y/' "${OUTPUT_DIR}/.config"
    elif ! grep -q '^BR2_LINUX_KERNEL_CUSTOM_TARBALL=y' "${OUTPUT_DIR}/.config"; then
      echo 'BR2_LINUX_KERNEL_CUSTOM_TARBALL=y' >> "${OUTPUT_DIR}/.config"
    fi
    # Set tarball location
    if grep -q '^BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=' "${OUTPUT_DIR}/.config"; then
      sed -i -E "s|^BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=.*$|BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=\"${TARBALL_URL}\"|" "${OUTPUT_DIR}/.config"
    else
      echo "BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=\"${TARBALL_URL}\"" >> "${OUTPUT_DIR}/.config"
    fi
    # Refresh config to account for edits
    make -C "${BUILDROOT_DIR}" olddefconfig O="${OUTPUT_DIR}" >/dev/null
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
