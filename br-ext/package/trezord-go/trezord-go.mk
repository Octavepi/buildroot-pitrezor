################################################################################
# Build trezord-go from source using Go
################################################################################

TREZORD_GO_VERSION = master
TREZORD_GO_SITE = https://github.com/trezor/trezord-go.git
TREZORD_GO_SOURCE = $(notdir $(TREZORD_GO_SITE))
TREZORD_GO_LICENSE = MIT
TREZORD_GO_DEPENDENCIES =

# Clone into package dir and use host go to build a linux/arm64 binary
define TREZORD_GO_BUILD_CMDS
\tgit clone --depth 1 $(TREZORD_GO_SITE) $(@D)/src || true
\tcd $(@D)/src && GOPATH=$(TOPDIR)/output/host/bin/goenv \\\n\t\t&& env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o trezord-go ./cmd/trezord-go || true
endef

define TREZORD_GO_INSTALL_TARGET_CMDS
\t$(INSTALL) -D -m 0755 $(@D)/src/trezord-go $(TARGET_DIR)/usr/bin/trezord-go || true
endef

$(eval $(generic-package))
