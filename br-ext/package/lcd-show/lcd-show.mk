# Wrapper for LCD-show (Waveshare display scripts)
LCD_SHOW_VERSION = master
LCD_SHOW_SITE = https://github.com/goodtft/LCD-show.git
LCD_SHOW_SITE_METHOD = git
LCD_SHOW_LICENSE = GPL-2.0

define LCD_SHOW_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/opt/lcd-show
	cp -r $(@D)/* $(TARGET_DIR)/opt/lcd-show/
endef

$(eval $(generic-package))
