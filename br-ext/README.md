# pitrezor-br-ext (Buildroot External)

Hardened Raspberry Pi image (Pi 0/2/3/4, 32-bit and 64-bit) that boots directly into the Trezor Core emulator and exposes the Suite Bridge (trezord-go) on TCP 21324 via the USB gadget interface (usb0), with:
- BusyBox init, no getty/login
- Read-only rootfs (mounted ro), tmpfs for /tmp, /var, /run
- Unprivileged 'trezor' user runtime
- iptables default-deny inbound; Bridge allowed only on usb0:21324
- sysctl hardening; quiet boot; KMS/DRM + SDL2 (no X/Wayland)
- First-boot touchscreen calibration; persistent calibration in /data/tslib

## Quick Start

```bash
# 1) Get Buildroot and this external
git clone --depth=1 https://github.com/buildroot/buildroot.git
git clone https://github.com/Octavepi/buildroot-pitrezor.git

# 2) From the buildroot directory, select a PiTrezor defconfig
cd buildroot
# Available defconfigs provided by this external:
#   rpi0_defconfig, rpi2_defconfig, rpi3_defconfig, rpi3-64_defconfig,
#   rpi4_defconfig, rpi4-64_defconfig
make BR2_EXTERNAL=../buildroot-pitrezor/br-ext rpi4-64_defconfig

# 3) (Optional) Customize packages
make menuconfig
# Target packages -> pitrezor external options -> trezord-go (enable if needed)

# 4) Build
make -j"$(nproc)"

# 5) Flash
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync
```

## Add the emulator files

Build the emulator for your target (preferably using the Buildroot SDK so it links
against the same SDL/Mesa as the image), then copy the `trezor-firmware` tree into:

`br-ext/overlay/opt/trezor-firmware/`

Rebuild after copying to include it in the image.

## Bridge exposure and firewall

- The Bridge (trezord) listens on 0.0.0.0, but the firewall only allows inbound
  connections on the USB gadget interface `usb0` to TCP 21324.
- Edit `overlay/etc/init.d/S20firewall` if you need different exposure:
  - To allow a specific LAN host, add an ACCEPT rule for that host and interface.
  - To restrict further, remove or modify the usb0 rule.

## Touchscreen calibration and persistence

- On first boot, `S05calibrate` runs `ts_calibrate`, stores calibration under `/data/tslib`,
  and marks completion with `/etc/.touch_calibrated`.
- If `/data` is not writable on first boot, it falls back to `/etc` so the device remains usable.

## Partitions

- Boot (FAT)
- Rootfs (ext4, mounted read-only)
- Data (ext4, mounted at `/data`, nosuid,nodev,noexec)