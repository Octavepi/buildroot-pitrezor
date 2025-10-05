LCD_SHOW_VERSION = master
LCD_SHOW_SITE = https://github.com/goodtft/LCD-show.git
LCD_SHOW_SITE_METHOD = git

define LCD_SHOW_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/opt/lcd-show
	cp -r $(@D)/* $(TARGET_DIR)/opt/lcd-show/
endef

$(eval $(generic-package))
