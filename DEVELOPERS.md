# Developer notes (PiTrezor)

This file captures practical steps for contributors working on the Buildroot external (`br-ext`).

## Add a new package

1. Create `br-ext/package/<name>/` with `<name>.mk` and `Config.in`.
2. Append a `source "$BR2_EXTERNAL_PITREZOR_PATH/package/<name>/Config.in"` line to `br-ext/Config.in`.
3. Select the package in menuconfig via the defconfig you’re working on, or add `BR2_PACKAGE_<NAME>=y` to a defconfig.
4. Build:

- `./bake.sh rpi4-64` (preferred)
- or classic make: `make -C buildroot BR2_EXTERNAL=br-ext rpi4-64_defconfig O=output/rpi4-64 && make -C buildroot -j"$(nproc)" O=output/rpi4-64`

Notes:

- `br-ext/external.mk` automatically includes all `*.mk` files under `br-ext/package/**`.
- Follow `$(generic-package)` unless you need a different Buildroot infra.

## Board/display tweaks

- Pass overlays/rotation through `bake.sh` so `post-image.sh` appends to `config.txt`:
  - `./bake.sh rpi4-64 waveshare35a 180`
- For quick post-build tweaks without a rebuild, use `./easy-bake.sh <deconfig> <overlays> <rotation>` which patches `config.txt` inside the image.

## Runtime & init

- Init scripts: `br-ext/overlay/etc/init.d/`
  - `S05calibrate`: first-boot touchscreen calibration; stores under `/data/tslib`, falls back to `/etc` if needed.
  - `S20firewall`: default-deny inbound; allows `usb0:21324` for trezord.
  - `S99trezor`: sets TSLIB/SDL env and launches trezord (if `usb0` exists) and `trezor-wallet` as user `trezor`.
- Filesystems: rootfs RO, `/tmp` `/var` `/run` tmpfs, persistent data under `/data`.

## Debugging

- Boot logs: Enable more verbosity by building in debug mode: `./bake.sh rpi4-64 "" "" debug` (turns off strip, enables debug, rootfs RW).
- Service status: Check `/var/log` in tmpfs or add temporary `set -x` to init scripts.
- Display input: Verify `/dev/input/touchscreen0`, `ts_calibrate`, and SDL env in `S99trezor`.
- USB gadget: Ensure `usb0` exists; otherwise trezord won’t start. Check `dtoverlay=dwc2` in `config.txt`.

## Hardening

- Global flags enforced via `br-ext/external.mk` (PIE/RELRO/SSP).
- Use `br-ext/hardening/pitrezor_hardening.fragment` for release defaults and `pitrezor_debug.fragment` for debug-friendly toggles in defconfigs.

## Where things live

- Defconfigs: `br-ext/configs/*_defconfig`
- Boot assets: `br-ext/board/pitrezor/{config.txt,cmdline.txt,genimage.cfg.in,post-image.sh}`
- Rootfs overlay: `br-ext/overlay/**`
- Packages: `br-ext/package/**`
- Users: `br-ext/users-table.txt`

## Releasing

- Artifact: `output/<deconfig>/images/sdcard.img`
- Optional quick customization: `output/easybake/<deconfig>/<deconfig>-final.img`
- Provide checksums and signatures alongside images.
