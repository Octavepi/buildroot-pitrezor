# Contributing to buildroot-pitrezor

Thanks for your interest in contributing to **PiTrezor**!  
This project is a Buildroot-based Trezor Core emulator for Raspberry Pi with touchscreen support.

## How to Contribute

1. **Fork the Repository**
   - Fork `Octavepi/buildroot-pitrezor` to your own GitHub account.
   - Clone your fork locally.

2. **Create a Branch**
   - Use a descriptive branch name:
     ```
     git checkout -b feature/add-display-driver
     ```

3. **Make Your Changes**
   - Ensure your code is clean, minimal, and documented.
   - Follow existing coding and file structure conventions.

4. **Commit Your Changes**
   - Use meaningful commit messages:
     ```
     git commit -m "Add support for Waveshare 4.3 display"
     ```

5. **Push and Submit a Pull Request**
   - Push your branch to your fork:
     ```
     git push origin feature/add-display-driver
     ```
   - Open a Pull Request (PR) on GitHub against `main`.

## Guidelines

- Keep commits focused and atomic.
- If adding new LCD overlays or board support, update `README.md` and `docs/PiTrezor_UserGuide.pdf`.
- Run a build locally before submitting PRs to confirm changes work.
- Respect GPLv3 license terms — any derivative code must remain GPL-compatible.

## Reporting Issues

- Use GitHub Issues to report bugs, request features, or suggest improvements.
- When reporting bugs, include:
  - Board model (e.g., Pi Zero, Pi 3B+, Pi 4)
  - LCD overlay used
  - Steps to reproduce
  - Logs or error messages

---

Thanks for helping improve **PiTrezor – Secure Wallet**!
