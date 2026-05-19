# Minino Firmware Flashing Guide for macOS

This guide provides step-by-step instructions for building and flashing the Minino firmware on macOS, specifically for the "hackGDL" build target/configuration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Homebrew Dependencies](#homebrew-dependencies)
3. [Python Setup](#python-setup)
4. [ESP-IDF 5.x Installation](#esp-idf-5x-installation)
5. [Environment Configuration](#environment-configuration)
6. [USB Permissions on macOS](#usb-permissions-on-macos)
7. [Identifying the Serial Port](#identifying-the-serial-port)
8. [Bootloader Mode](#bootloader-mode)
9. [Flashing Instructions](#flashing-instructions)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- macOS 10.15 (Catalina) or later
- Administrator access to install software
- USB cable (data-capable, not charge-only)
- Minino hardware (ESP32-C6 based)

---

## Homebrew Dependencies

First, install [Homebrew](https://brew.sh) if you haven't already:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install required dependencies:

```bash
# Install Python 3.11 (required for ESP-IDF 5.x)
brew install python@3.11

# Install USB driver for common serial chips (optional but recommended)
brew install --cask serial

# Install build tools (if not already present)
brew install cmake ninja
```

---

## Python Setup

ESP-IDF 5.x requires Python 3.11 (preferred) or Python 3.10/3.12.

### Verify Python Installation

```bash
python3.11 --version
# Should output: Python 3.11.x
```

### Create Python Virtual Environment (Recommended)

ESP-IDF 5.x works best with a dedicated virtual environment:

```bash
# Create virtual environment
python3.11 -m venv ~/esp/esp-idf-venv

# Activate virtual environment
source ~/esp/esp-idf-venv/bin/activate

# Upgrade pip
pip install --upgrade pip
```

---

## ESP-IDF 5.x Installation

### Option 1: Official Espressif Installer (Recommended)

1. Download the ESP-IDF 5.x installer from:
   https://github.com/espressif/esp-idf/releases/tag/v5.3.2

2. Choose the offline installer for macOS

3. Run the installer and follow the prompts:
   ```bash
   # Example installation to ~/esp/esp-idf
   cd ~/esp
   git clone -b v5.3.2 --recursive https://github.com/espressif/esp-idf.git
   cd esp-idf
   ./install.sh esp32c6
   ```

4. Install ESP32-C6 target specifically:
   ```bash
   cd ~/esp/esp-idf
   python -m pip install --upgrade pip
   ./install.sh esp32c6
   ```

### Option 2: Using Existing ESP-IDF Installation

If you already have ESP-IDF installed:

```bash
# Check version
idf.py --version

# Must be ESP-IDF 5.x (5.0 - 5.4)
# If you have ESP-IDF 6.x, you'll need to install 5.x separately
```

---

## Environment Configuration

### Add to `.zshrc` (macOS default shell)

Add the following to your `~/.zshrc` file:

```bash
# ESP-IDF 5.x Configuration for Minino
export IDF_PATH="$HOME/esp/esp-idf"
export IDF_TOOLS_PATH="$HOME/.espressif"

# Optional: Add convenience aliases
alias idf5='. $IDF_PATH/export.sh'
alias minino-build='cd ~/path/to/minino/firmware && ./build.sh'
```

Apply changes:

```bash
source ~/.zshrc
```

### Verify Installation

```bash
# Source ESP-IDF environment
. $IDF_PATH/export.sh

# Verify
idf.py --version
# Should show: ESP-IDF 5.x.x
```

---

## USB Permissions Considerations on macOS

macOS generally handles USB serial devices automatically, but you may need to:

### 1. Check Device Recognition

```bash
# List USB devices
lsusb

# List serial ports
ls -l /dev/cu.*
```

### 2. Common USB-to-Serial Chip Drivers

- **FTDI**: Built-in to macOS 10.9+
- **CP210x**: May need driver from [Silicon Labs](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- **CH340/CH341**: Built-in to macOS 10.15+ (may need `sudo` for older versions)

### 3. Permission Issues

If you get "Permission denied":

```bash
# Check permissions
ls -l /dev/cu.usbserial*

# If needed, add user to dialout group (rarely needed on macOS)
sudo dseditgroup -o edit -a $(whoami) -t user dialout
```

---

## Identifying the Serial Port

### Auto-detection

The build script auto-detects the serial port. To see what's detected:

```bash
# List all serial ports
ls -l /dev/cu.*

# Common patterns:
# FTDI:    /dev/cu.usbserial-XXXXXXXX
# CP210x:  /dev/cu.usbserial-XXXXXXXX
# CH340:   /dev/cu.usbserial-XXXXXXXX
# CDC ACM: /dev/cu.usbmodemXXXXXXXX
```

### Before/After Comparison

```bash
# Disconnect Minino, run:
ls /dev/cu.* | sort > before.txt

# Connect Minino, run:
ls /dev/cu.* | sort > after.txt

# Compare to find the new device
diff before.txt after.txt
```

### Using the Build Script

```bash
# Auto-detect (script will show detected port)
./build.sh flash

# Or specify manually
export PORT=/dev/cu.usbserial-12345
./build.sh flash
```

---

## Bootloader Mode

The Minino may need to put into bootloader mode for flashing.

### Method 1: Using Boot Button

1. Hold the **BOOT** button on Minino
2. Press and release the **RESET** button
3. Release the **BOOT** button
4. The device is now in bootloader mode
5. Flash the firmware

### Method 2: Software Reset

If the device is already configured for auto-reset:

```bash
# The build script handles this automatically
./build.sh flash
```

### Method 3: GPIO0 Method

For ESP32-C6, the bootloader pin may differ. Check Minino documentation for specific button combinations.

---

## Flashing Instructions

### Quick Start (Using Build Script)

```bash
# Navigate to firmware directory
cd /path/to/minino/firmware

# Build only
./build.sh

# Build and flash
./build.sh flash

# Build, flash, and monitor
./build.sh all

# Full clean and rebuild
./build.sh fullclean
./build.sh all
```

### Manual Flashing (Using idf.py)

If you prefer manual control:

```bash
# Navigate to firmware directory
cd /path/to/minino/firmware

# Set target chip (first time only)
idf.py set-target esp32c6

# Build
idf.py build

# Flash (replace PORT with your actual port)
idf.py -p /dev/cu.usbserial-XXXX flash

# Monitor
idf.py -p /dev/cu.usbserial-XXXX monitor

# Flash and monitor
idf.py -p /dev/cu.usbserial-XXXX flash monitor
```

### Flashing "hackGDL" Configuration

The "hackGDL" build uses the standard Minino configuration:

```bash
# Using the profile system
idf.py @profiles/minino build

# Or with sdkconfig override
cp sdkconfig.minino sdkconfig
idf.py build
```

### Erase Flash (Clean Install)

```bash
# Erase entire flash
idf.py -p /dev/cu.usbserial-XXXX erase_flash

# Then flash normally
idf.py -p /dev/cu.usbserial-XXXX flash
```

### Monitor Serial Output

```bash
# Start monitoring
idf.py -p /dev/cu.usbserial-XXXX monitor

# Exit monitor: Ctrl + ]
```

---

## Troubleshooting

### Missing Serial Port

**Problem**: No serial port detected

**Solutions**:

1. Check USB cable - ensure it's data-capable (not charge-only)
2. Try a different USB port
3. Try a different USB cable
4. Install appropriate drivers:
   - FTDI: Usually built-in
   - CP210x: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
   - CH340: Built-in to macOS 10.15+

```bash
# List USB devices
system_profiler SPUSBDataType

# Check for serial devices
ls -l /dev/cu.*
```

### Permission Denied

**Problem**: `Permission denied` when accessing serial port

**Solutions**:

1. Check if another process is using the port (Arduino IDE, screen, etc.)
2. Close any other serial monitors
3. Try:
   ```bash
   sudo kill -9 $(lsof -t -i /dev/cu.usbserial*)
   ```
4. Restart your terminal
5. Reconnect the USB device

### Wrong Chip Target

**Problem**: Build fails with target mismatch errors

**Solution**:

```bash
# Reset target to ESP32-C6
cd /path/to/minino/firmware
idf.py set-target esp32c6

# Rebuild
idf.py build
```

### Python Virtualenv Issues

**Problem**: ESP-IDF tools not found or Python version mismatch

**Solutions**:

1. Activate the correct Python environment:
   ```bash
   source ~/esp/esp-idf-venv/bin/activate
   ```

2. Re-run ESP-IDF installation:
   ```bash
   cd ~/esp/esp-idf
   ./install.sh esp32c6
   ```

3. Source export script:
   ```bash
   . ~/esp/esp-idf/export.sh
   ```

4. Verify:
   ```bash
   python --version  # Should be 3.11
   idf.py --version  # Should be 5.x
   ```

### Old Cached Builds

**Problem**: Strange build errors or outdated behavior

**Solution**:

```bash
# Full clean
./build.sh fullclean

# Or manually
rm -rf build/ managed_components/ sdkconfig dependencies.lock

# Rebuild
./build.sh
```

### "Failed to Connect to ESP32"

**Problem**: `A fatal error occurred: Failed to connect to ESP32`

**Solutions**:

1. **Try holding BOOT button during flash**:
   - Hold BOOT button
   - Connect USB
   - Release BOOT after 2 seconds
   - Run flash command

2. **Check baud rate**:
   ```bash
   # Try slower baud rate
   idf.py -p /dev/cu.usbserial-XXXX --baud 115200 flash
   ```

3. **Reset the device**:
   - Disconnect USB
   - Wait 5 seconds
   - Reconnect USB
   - Try again

4. **Check power**:
   - Use a powered USB hub
   - Ensure USB port provides sufficient power

5. **Bootloader mode**:
   - Some boards require manual bootloader entry
   - See [Bootloader Mode](#bootloader-mode) section

### USB Cable Power-Only Issue

**Problem**: Device powers on but not detected by computer

**Symptoms**:
- LED lights up but no serial port appears
- Device vibrates/gets warm but not in `ls /dev/cu.*`

**Solutions**:

1. **Replace USB cable** - many cables are charge-only
2. **Use original cable** that came with Minino
3. **Try different USB port** - some ports provide less power
4. **Use powered USB hub** if available

### ESP-IDF Version Conflicts

**Problem**: Multiple ESP-IDF versions causing issues

**Solution**:

```bash
# Check current version
idf.py --version

# If wrong version, source the correct export.sh
. ~/esp/esp-idf/export.sh  # ESP-IDF 5.x

# Verify
idf.py --version  # Should show 5.x.x
```

### Build Errors After ESP-IDF Update

**Problem**: Build fails after updating ESP-IDF

**Solutions**:

1. Clean build artifacts:
   ```bash
   ./build.sh fullclean
   ```

2. Reinstall ESP-IDF dependencies:
   ```bash
   cd ~/esp/esp-idf
   ./install.sh esp32c6
   ```

3. Check compatibility:
   - ESP-IDF 5.0-5.4 are supported
   - ESP-IDF 6.x may have compatibility issues

### Zigbee/Thread Issues

**Problem**: Zigbee or Thread components fail to build

**Solutions**:

1. Ensure ESP32-C6 target is set (required for Zigbee)
2. Check sdkconfig has:
   ```
   CONFIG_ZB_ENABLED=y
   CONFIG_OPENTHREAD_ENABLED=y
   ```
3. Reinstall managed components:
   ```bash
   rm -rf managed_components
   idf.py reconfigure
   ```

---

## Quick Reference Commands

```bash
# Build firmware
./build.sh

# Flash to device
./build.sh flash

# Monitor output
./build.sh monitor

# Build + Flash + Monitor
./build.sh all

# Clean everything
./build.sh fullclean

# Erase flash
./build.sh erase

# Manual commands
idf.py set-target esp32c6     # Set chip target
idf.py build                  # Build
idf.py -p PORT flash          # Flash
idf.py -p PORT monitor        # Monitor
idf.py -p PORT erase_flash    # Erase all
```

---

## Additional Resources

- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/v5.3/esp32c6/)
- [ESP32-C6 Technical Reference Manual](https://www.espressif.com/sites/default/files/documentation/esp32c6_teical_rm.pdf)
- [Minino Hardware Documentation](../../hardware/)
- [Espressif GitHub](https://github.com/espressif)

---

## Support

For issues specific to:
- **ESP-IDF**: https://github.com/espressif/esp-idf/issues
- **Minino Hardware**: Check hardware documentation
- **Build Issues**: See troubleshooting section above
