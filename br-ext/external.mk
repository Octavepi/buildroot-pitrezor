# External.mk - tie external packages into buildroot

include $(sort $(wildcard $(BR2_EXTERNAL_PITREZOR_PATH)/package/*/*.mk))
