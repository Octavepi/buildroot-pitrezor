# External.mk for PiTrezor br-ext
# Auto-include all package makefiles in br-ext/package
include $(sort $(wildcard $(BR2_EXTERNAL_PITREZOR_PATH)/package/*/*.mk))

# Enforce PIE, RELRO, and hardening flags on all packages
TARGET_CFLAGS += -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE -pie
TARGET_LDFLAGS += -Wl,-z,relro,-z,now