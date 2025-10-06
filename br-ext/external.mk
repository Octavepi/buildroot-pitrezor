# External.mk for PiTrezor br-ext
# Auto-include all package makefiles in br-ext/package
include $(sort $(wildcard $(BR2_EXTERNAL_PITREZOR_PATH)/package/*/*.mk))
