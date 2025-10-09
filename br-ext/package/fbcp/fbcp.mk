################################################################################
#
# fbcp
#
################################################################################

FBCP_VERSION = master
FBCP_SITE = https://github.com/tasanakorn/rpi-fbcp.git
FBCP_SITE_METHOD = git
FBCP_LICENSE = MIT
FBCP_LICENSE_FILES = LICENSE

define FBCP_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" -C $(@D)
endef

define FBCP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/fbcp $(TARGET_DIR)/usr/bin/fbcp
endef

$(eval $(generic-package))
