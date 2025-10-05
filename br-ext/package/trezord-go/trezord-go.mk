# Wrapper for trezord-go
TREZORD_GO_VERSION = master
TREZORD_GO_SITE = https://github.com/trezor/trezord-go.git
TREZORD_GO_SITE_METHOD = git
TREZORD_GO_LICENSE = MIT
TREZORD_GO_LICENSE_FILES = LICENSE

define TREZORD_GO_BUILD_CMDS
	$(MAKE) -C $(@D)
endef

define TREZORD_GO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/trezord $(TARGET_DIR)/usr/bin/trezord
endef

$(eval $(generic-package))
