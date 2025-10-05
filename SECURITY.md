# Security Policy

If you discover a security vulnerability in PiTrezor, please report it responsibly.

## Reporting a Vulnerability
- Email: 101262679+Octavepi@users.noreply.github.com
- Please do not open a public issue until the vulnerability is patched.
- Provide as much detail as possible (steps to reproduce, environment, version).

We take security seriously and will acknowledge your report within a reasonable timeframe.

# PiTrezor Security Notes

PiTrezor is a minimal Buildroot-based image that turns a Raspberry Pi into a Trezor-like hardware wallet.
Since the Pi does not support secure boot, users must follow best practices to ensure safety.

## Key Security Points
- **Passphrase Required**: Always enable and use a strong passphrase. Without it, seeds or keys on the SD card can be extracted if the card is accessed.
- **Verify Releases**: Always verify `.sha256` checksums and `.sig` GPG signatures before flashing.
- **Submodule Integrity**: All submodules are pinned; upstream repos should be verified where possible.
- **Firmware Authenticity**: No hardware secure boot; trust only signed or self-built images.

## Recommendations
- Back up your recovery seed in a safe place.
- Never connect PiTrezor to untrusted machines.