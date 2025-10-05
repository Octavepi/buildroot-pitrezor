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

Example for Raspberry Pi 4 with LCD-show drivers and 180° rotation:

```bash
./build.sh rpi4 LCD-show 180
```

### 4. Flash and Boot

After the build completes, flash:

```
output/images/sdcard.img
```

to your SD card and boot the Pi.

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
