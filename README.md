# PiTrezor – Secure Wallet (Universal Buildroot Image)

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Build: Manual](https://img.shields.io/badge/build-manual-lightgrey.svg)
![Platform: Raspberry Pi](https://img.shields.io/badge/platform-Raspberry%20Pi-red.svg)
![Status: Stable](https://img.shields.io/badge/status-stable-brightgreen.svg)

## Overview

PiTrezor is a **Buildroot-based universal firmware image** that turns a Raspberry Pi (Zero, 3, 4) with a touchscreen display into a secure, standalone Trezor-like hardware wallet emulator.

---

## Quick Start

### 1. Install Build Dependencies

PiTrezor builds have been tested on **Ubuntu 22.04 / 24.04 LTS** and other Debian-based distros.  
Building on an **x86_64 machine (desktop/laptop)** is recommended, because Buildroot will cross-compile for ARM much faster than building natively on the Pi.

On Ubuntu/Debian (x86_64 host):

```bash
sudo apt update
sudo apt install -y build-essential git python3 unzip bc wget curl
```

On Raspberry Pi (native build — works but will be much slower):

```bash
sudo apt update
sudo apt install -y build-essential git python3 unzip bc wget curl
```

### 2. Clone the Repo with Submodules

```bash
git clone --recurse-submodules git@github.com:Octavepi/buildroot-pitrezor.git
cd buildroot-pitrezor
```

If you forgot `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 3. Build for Your Raspberry Pi

Example for Raspberry Pi 4 with waveshare35a drivers and 180° rotation:

```bash
./bake.sh rpi4 waveshare35a 180
```

## Easy-Bake Workflow

- Run a full build without overlay/rotation to generate a base image:

  ```bash
  ./bake.sh rpi4-64
  ```

  → Saves `output/base/rpi4-64/base-rpi4-64.img`

- Use `easy-bake.sh` to create a customized image quickly (overlays, rotation),
  which patches `config.txt` inside the image’s boot partition and writes out a
  new artifact under the same deconfig path:

  ```bash
  ./easy-bake.sh rpi4-64 waveshare35a 180
  ```

  → Produces `output/easybake/rpi4-64/rpi4-64-final.img`

### 4. Flash and Boot

**Recommended:** Use [Balena Etcher](https://etcher.balena.io) or [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to write `output/images/sdcard.img` to your SD card.  
These tools are safer and easier than command-line methods.
Boot your Pi with the SD card and LCD attached.

### First Boot

- Splash screen: **“PiTrezor – Secure Wallet”**
- Touchscreen calibration runs once
- Wallet starts automatically after calibration

## ⚠️ Security Notes

- Always use a strong passphrase with PiTrezor. Without one, keys/seeds on the SD card can be extracted.
- Verify release signatures (`.sha256` and `.sig` files) before flashing an image.
- No secure boot on Raspberry Pi — only trust images you build yourself or those signed by the maintainer.

---

## Features

- Universal build script with Pi Zero / Pi 3 / Pi 4 support
- LCD overlay + rotation argument support
- First-boot touchscreen calibration flow
- Branded splash screen ("PiTrezor – Secure Wallet")
- USB HID emulation for use with Trezor Suite
- GPLv3 licensed

## Firmware Updates

Unlike a real Trezor hardware wallet, PiTrezor cannot update firmware directly through Trezor Suite.  
Suite expects a bootloader and flash memory layout that the Raspberry Pi does not have.

When Trezor firmware is updated upstream, you (or maintainers) must rebuild PiTrezor against the new firmware.

- New ready-to-flash images may be published under GitHub Releases.
- Users update by reflashing the new image with Balena Etcher or Raspberry Pi Imager.
- Your wallet seed remains valid; just restore it after flashing.

This approach keeps PiTrezor secure and avoids opening network or write-access paths inside the device.

## Documentation

See the [PiTrezor User Guide (PDF)](docs/PiTrezor_UserGuide.pdf) for detailed setup instructions.

---

## Developer Notes

### Config.in

The file `br-ext/Config.in` is currently maintained manually.

- When adding a new package under `br-ext/package/<name>/`, add a `source` line
  referencing its `Config.in` to `br-ext/Config.in`.
- `br-ext/external.mk` auto-includes all `*.mk` files via wildcard; the `Config.in`
  wiring controls visibility in menuconfig/defconfigs.
- If we later add codegen for `Config.in`, this README will be updated accordingly.

### Build Script Paths

`bake.sh` auto-detects your repo root and passes absolute paths to Buildroot.  
This ensures the build works regardless of where `docs/` or other folders sit.

---

## Acknowledgment

This build and repository were created with the assistance of ChatGPT.  
Bring your ideas to life with [ChatGPT](https://chat.openai.com).

---

## Contributing

We welcome community contributions!  
Please review the following before contributing:

- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

---

## License

This project is licensed under the [GPLv3](LICENSE).

---

## Support This Project

If you’d like to support development:

- **Bitcoin**: `bc1qf2u9emuzsn2hqj3u0ypwuate0ammn2zm2k63gz`
- **Ethereum**: `0x87efd0009D4abaa4DD91c2B2452AE82CE3430CF6`
- **Solana**: `3MvBX4m6DzG2bv3ArvscQRBWSMPY1Jiqce5zUjkBfk4d`
- **Cash App**: `$Truth369`
- **Venmo**: `@Truth369`

---

PiTrezor – Secure Wallet  
© 2025 Octavepi
