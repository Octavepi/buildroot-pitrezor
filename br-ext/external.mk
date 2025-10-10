# External.mk for PiTrezor br-ext
# Auto-include all package makefiles in br-ext/package
include $(sort $(wildcard $(BR2_EXTERNAL_PITREZOR_PATH)/package/*/*.mk))

# Note: Hardening flags are controlled via Buildroot config fragments
# (see br-ext/hardening/*.fragment). Avoid injecting global TARGET_* flags here
# to prevent leaking -pie/-fPIE into toolchain builds (e.g., libgcc), which can
# cause link failures. Target packages will inherit the appropriate flags from
# the selected BR2_* options.