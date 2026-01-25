# AWSW ESP32 Flash Script - Linux Version

Linux version of the AWSW ESP32 flash script for Debian, Ubuntu, and other distributions. (tested in particular on Debian 12)

**No Arduino IDE required - fully automated flashing!**

## Quick Start

```bash
cd AWSW-ESP32-flash-script/Script/Linux
bash linux-flash-script.sh
```

**No sudo required!** The script runs in user context and will guide you through any setup.

## Prerequisites

- **Python 3** with `python3-venv` (installed on most systems)
- **wget or curl** (for downloading firmware)
- **dialout group** membership (script will guide you if needed)

One-time setup if prompted:
```bash
# Install Python3 venv (Debian/Ubuntu)
sudo apt-get install python3 python3-venv wget

# Add yourself to dialout group (for serial port access)
sudo usermod -a -G dialout $USER
# Then log out/in or run: newgrp dialout
```

## Features

- ✅ Runs in user context (no root required)
- ✅ Isolated Python virtual environment
- ✅ Smart permission handling
- ✅ Automatic ESP32 detection
- ✅ Clean removal (just delete `.tmp` folder)

## Security Notice

Firmware is downloaded over **HTTP** (not HTTPS). The script warns you before download. Use only on trusted networks. See the script source for details.

## Troubleshooting

**ESP32 not detected:**
```bash
ls /dev/ttyUSB* /dev/ttyACM*   # Check for device
dmesg | grep tty               # Check kernel messages
```

**Permission denied:** Add yourself to the dialout group (see Prerequisites).

## Cleanup

```bash
rm -rf .tmp  # Remove all temporary files
```

## Acknowledgments

- Original Windows script: [AWSW](https://github.com/AWSW-de)
- macOS version: [@johnneerdael](https://github.com/johnneerdael)
- Linux version: [@scinnod](https://github.com/scinnod)

## License

GPL-3.0-or-later - See [LICENSE](../../LICENSE) file.

---
**IMPORTANT: You are using this script at your own risk!**
