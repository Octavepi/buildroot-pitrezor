# PiTrezor – Secure Wallet (Universal Buildroot Image)

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Build: Manual](https://img.shields.io/badge/build-manual-lightgrey.svg)
![Platform: Raspberry Pi](https://img.shields.io/badge/platform-Raspberry%20Pi-red.svg)
![Status: Stable](https://img.shields.io/badge/status-stable-brightgreen.svg)

## Overview
PiTrezor is a **Buildroot-based universal firmware image** that turns a Raspberry Pi (Zero, 3, 4) with a touchscreen display into a secure, standalone Trezor-like hardware wallet emulator.

Features:
- Universal build script with Pi Zero / Pi 3 / Pi 4 support
- LCD overlay + rotation argument support
- First-boot touchscreen calibration flow
- Branded splash screen ("PiTrezor – Secure Wallet")
- USB HID emulation for use with Trezor Suite
- GPLv3 licensed

## Quick Start

### Clone the Repo
Make sure to use `--recurse-submodules` so all dependencies are pulled in:

```bash
git clone --recurse-submodules git@github.com:Octavepi/buildroot-pitrezor.git
cd buildroot-pitrezor
```

If you forgot to add `--recurse-submodules` during clone, run:
```bash
git submodule update --init --recursive
```

### Build Example
To build for Raspberry Pi 4 with default LCD drivers and 180° rotation:

```bash
./build.sh rpi4 LCD-show 180
```

### Output Image
After the build completes, the SD card image will be available at:

```
output/images/sdcard.img
```

Flash this to an SD card and boot your Raspberry Pi.

### First Boot
- Splash screen: **“PiTrezor – Secure Wallet”**
- Touchscreen calibration runs once
- Wallet starts automatically after calibration

## Documentation
See the [PiTrezor User Guide (PDF)](docs/PiTrezor_UserGuide.pdf) for detailed setup instructions.

## Contributing
We welcome community contributions!  
Please review the following before contributing:

- [Contributing Guidelines](CONTRIBUTING.md)  
- [Code of Conduct](CODE_OF_CONDUCT.md)  
- [Security Policy](SECURITY.md)  

## License
This project is licensed under the [GPLv3](LICENSE).

---
PiTrezor – Secure Wallet  
© 2025 Octavepi
