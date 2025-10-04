# PiTrezor – Secure Wallet (Universal Buildroot Image)

PiTrezor is a Buildroot-based distribution that turns a Raspberry Pi into a Trezor Core emulator with full touchscreen support.  
It includes a branded splash screen, one-time calibration flow, locked-down OS, and Trezor Bridge integration — making it behave as closely as possible to a real hardware wallet for development and personal use.  

Supports Raspberry Pi Zero, 3, and 4 with multiple LCD overlays and rotation options.

---

# PiTrezor – Secure Wallet (Raspberry Pi)

Minimal Buildroot-based image that boots a Trezor Core **emulator** on Raspberry Pi boards with touchscreens. Includes locked-down OS, splash screen, automatic first-boot calibration, and Trezor Bridge (trezord-go).

> Note: This is an emulator for development/personal use. It does **not** provide the tamper resistance of real hardware.

## Clone (with submodules)
```bash
git clone --recurse-submodules https://github.com/YOUR_USERNAME/pitrezor.git
cd pitrezor
```
If you forget the recurse flag:
```bash
git submodule update --init --recursive
```

## Build prerequisites (Ubuntu)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex gettext libncurses5-dev   unzip rsync file wget python3 perl cpio diffutils sed patch tar pkg-config   scons clang llvm-dev protobuf-compiler cmake golang-go
```

## Build
```bash
./build.sh <board> <lcd_overlay> <rotation>
```
Examples:
```bash
./build.sh rpi4 waveshare35a 270
./build.sh rpi3 LCD-show 180
./build.sh rpi0 mylcd 0
```
Boards supported: Pi Zero (rpi0), Pi 3 (rpi3), Pi 4 (rpi4).  
LCD overlays: any dtoverlay supported by Raspberry Pi OS (waveshare35a, LCD-show, etc.).  
Rotation: 0, 90, 180, 270.

Image output: `third_party/buildroot/output/images/sdcard.img`

## Flash to SD
```bash
sudo dd if=third_party/buildroot/output/images/sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

## First boot
- Splash: **“PiTrezor – Secure Wallet”**
- First boot only: touchscreen calibration (tap crosshairs)
- Message: “Calibration complete – starting wallet…”
- Emulator starts on TFT; tap on-screen Confirm/Cancel buttons.

## Connect to Trezor Suite
- Plug Pi → host with a data-capable USB cable
- Host may auto-assign IP; if not, set host USB interface to `169.254.9.2/16`
- Suite connects to Bridge at: `http://169.254.9.1:21324`

## Recalibrate
- Delete `/etc/.touch_calibrated` from the SD card and reboot.

## Recovery
- Edit `/boot/firmware/config.txt` or `cmdline.txt` on the SD card
- Or re-flash from a saved `sdcard.img`
