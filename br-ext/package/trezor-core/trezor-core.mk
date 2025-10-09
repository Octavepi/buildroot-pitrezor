################################################################################
#
# trezor-core
#
################################################################################

TREZOR_CORE_VERSION = master
TREZOR_CORE_SITE = https://github.com/Octavepi/trezor-firmware.git
TREZOR_CORE_SITE_METHOD = git
TREZOR_CORE_SUBDIR = core
TREZOR_CORE_LICENSE = GPL-3.0
TREZOR_CORE_LICENSE_FILES = LICENSE

# Build commands — adjust for trimmed fork
define TREZOR_CORE_BUILD_CMDS
	$(MAKE) -C $(@D)/core
endef

# Install commands — adjust if trimmed repo has different entry points
define TREZOR_CORE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/core/trezorctl $(TARGET_DIR)/usr/bin/trezorctl || true
	$(INSTALL) -D -m 0755 $(@D)/core/emu.py   $(TARGET_DIR)/usr/bin/trezor-wallet || true
endef

$(eval $(generic-package))
