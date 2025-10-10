## Copilot instructions for PiTrezor (Buildroot external)

What this repo is

- A Buildroot-based “external” called `br-ext` that builds a hardened Raspberry Pi image which boots directly into a Trezor Core emulator and exposes the Suite Bridge (trezord-go) via USB gadget interface `usb0:21324`.
- Big pieces: `br-ext/` (packages, overlay, hardening, board assets), upstream `buildroot/` (submodule or vendor copy), and two helper scripts `bake.sh` and `easy-bake.sh`.

How the build works (end-to-end)

- Preferred: use `./bake.sh <deconfig> [overlay] [rotation] [debug]`. It sets `BR2_EXTERNAL=br-ext`, selects a defconfig, exports optional display args to the board post-image, and runs Buildroot.
- Outputs live under `output/<deconfig>/`; the image is `output/<deconfig>/images/sdcard.img`.
- Board post-processing `br-ext/board/pitrezor/post-image.sh`:
  - Appends `dtoverlay=${PITREZOR_DTO}` (comma-separated list) and `display_rotate=${PITREZOR_ROT}` to `config.txt`.
  - Auto-detects the DTB (Pi 0/2/3/4 variants) and selects the correct `start*.elf`/`fixup*.dat` pair. Update the candidate list if you add new boards.

Daily commands (examples)

- Build Pi 4 (64-bit), Waveshare 3.5 overlay, 180° rotation:
  ```bash
  ./bake.sh rpi4-64 waveshare35a 180
  ```
- “Classic” Buildroot invocation (equivalent to the script):
  ```bash
  make -C buildroot BR2_EXTERNAL=br-ext rpi4-64_defconfig O=output/rpi4-64
  make -C buildroot -j"$(nproc)" O=output/rpi4-64
  ```

Runtime model (why things boot the way they do)

- Init scripts in `br-ext/overlay/etc/init.d/`:
  - `S05calibrate` runs one-time touchscreen calibration; persists under `/data/tslib`. Falls back to `/etc` if `/data` isn’t writable on first boot.
  - `S20firewall` enforces default-deny inbound; only `usb0:21324` is allowed for trezord.
  - `S99trezor` sets TSLIB/SDL env and launches `trezord` (if `usb0` exists) and the emulator (`/usr/bin/trezor-wallet`) as unprivileged user `trezor` (see `br-ext/users-table.txt`).
- Rootfs is read-only by default; volatile paths (`/tmp`, `/var`, `/run`) are tmpfs. Persistent data lives in `/data`.

Project conventions you should follow

- Security/hardening: `br-ext/external.mk` enforces PIE/RELRO/SSP across all packages. Extra config fragments in `br-ext/hardening/` (release vs debug) inform defconfigs; `bake.sh ... debug` also writes debug-friendly toggles into `O/.config`.
- Packaging: add new packages under `br-ext/package/<name>/<name>.mk` and `Config.in`. Reference them from `br-ext/Config.in` via `source` lines. `external.mk` uses a wildcard to include `*.mk` in the build. Use `$(generic-package)` unless you need a custom infra.
- Board/display: prefer passing display overlays/rotation via `bake.sh` so `post-image.sh` appends to `config.txt` (e.g., `PITREZOR_DTO=waveshare35a`, `PITREZOR_ROT=180`).

Integration points

- Trezor Core: `br-ext/package/trezor-core` pulls from `https://github.com/Octavepi/trezor-firmware.git` and installs `trezor-wallet` (wrapper on `core/emu.py`) and `trezorctl` when present.
- Bridge: `br-ext/package/trezord-go` builds upstream `trezord-go` as `/usr/bin/trezord`.
- Optional display mirroring: `br-ext/package/fbcp` to mirror HDMI to SPI TFTs when needed.

Where to look when making changes

- Defconfigs: `br-ext/configs/*_defconfig`. Use these to control BR packages and include `br-ext/hardening/*.fragment` options.
- Boot assets: `br-ext/board/pitrezor/{config.txt,cmdline.txt,genimage.cfg.in,post-image.sh}`.
- Rootfs overlay: `br-ext/overlay/**` (init, sysctl, udev, splash, tslib files).

Gotchas and current quirks

- Easy-bake: Now standardized. `bake.sh` saves base under `output/base/<deconfig>/base-<deconfig>.img`; `easy-bake.sh` reads that, patches boot `config.txt`, and writes `output/easybake/<deconfig>/<deconfig>-final.img`.
- `br-ext/Config.in` is manual for now. Add `source` lines when adding packages; `external.mk` already wildcard-includes `*.mk`.
- Firewall defaults block LAN; if you need exposure off-USB, change `S20firewall` explicitly.

Questions or clarifications to confirm

- If we want automated `Config.in` generation, specify the desired generator and hook (e.g., during `bake.sh`); otherwise we’ll keep it manual and documented.
