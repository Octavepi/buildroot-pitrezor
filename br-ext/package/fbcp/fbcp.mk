# Wrapper for fbcp (framebuffer copy utility)
FBCP_VERSION = master
FBCP_SITE = https://github.com/juj/fbcp-ili9341.git
FBCP_SITE_METHOD = git
FBCP_LICENSE = MIT

define FBCP_BUILD_CMDS
	$(MAKE) -C $(@D)
endef

define FBCP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/fbcp $(TARGET_DIR)/usr/bin/fbcp
endef

$(eval $(generic-package))
