# pitrezor-br-ext (Buildroot External)

Hardened Raspberry Pi 4 (aarch64) image that boots directly into the Trezor
Core emulator and exposes the Suite Bridge (trezord-go) on TCP 21324, with:
- BusyBox init, no getty/login
- Read-only rootfs (mounted ro), tmpfs for /tmp,/var,/run
- Unprivileged 'trezor' user runtime
- iptables default-deny inbound; Bridge bound to 127.0.0.1 by default
- sysctl hardening; quiet boot; KMS/DRM + SDL2 (no X/Wayland)

## Quick Start
```bash
git clone --depth=1 https://github.com/buildroot/buildroot.git
# Put this folder next to buildroot/ as pitrezor-br-ext/
cd buildroot

# (Optional) Enable Bridge package in menuconfig:
make BR2_EXTERNAL=../pitrezor-br-ext pitrezor_rpi4_64_defconfig
make menuconfig   # Select: Target packages -> pitrezor external options -> trezord-go

# Build
make -j$(nproc)

# Flash
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync
```

## Add the emulator files
Build the emulator for ARM64 using the Buildroot SDK (so it links to the same
SDL/Mesa as the image), then copy the trezor-firmware tree into:
`pitrezor-br-ext/overlay/opt/trezor-firmware/` before you `make` (or rebuild after copying).

## Exposing Bridge to another machine
By default the firewall allows only localhost:21324. To allow a specific LAN PC,
edit `overlay/etc/init.d/S20firewall` and replace `127.0.0.1` with that PC's IP,
or add an additional ACCEPT rule.
