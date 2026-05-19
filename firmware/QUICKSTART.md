# Minino Firmware - Quick Start Guide

## Quick Build & Flash

### Method 1: Using use_idf5 (Recommended)

```bash
# 1. Switch to ESP-IDF 5.x environment
use_idf5

# 2. Navigate to firmware directory
cd /path/to/minino/firmware

# 3. Build and flash
./build.sh flash
```

### Method 2: Manual Environment Setup

```bash
# 1. Source ESP-IDF environment manually
. ~/esp/esp-idf/export.sh

# 2. Navigate to firmware
cd /path/to/minino/firmware

# 3. Build and flash
./build.sh flash
```

## Build Commands

| Command | Description |
|---------|-------------|
| `./build.sh` | Build firmware |
| `./build.sh flash` | Build and flash to device |
| `./build.sh all` | Build, flash, and monitor |
| `./build.sh clean` | Clean build artifacts |
| `./build.sh monitor` | Monitor serial output |

## Troubleshooting

### "ESP-IDF 5.x not found!"

Run `use_idf5` first:

```bash
use_idf5
./build.sh
```

### No Serial Port

```bash
# List available ports
ls -l /dev/cu.*

# Specify port manually
PORT=/dev/cu.usbserial-XXXX ./build.sh flash
```

### Permission Denied

- Close any other serial applications (Arduino IDE, screen, etc.)
- Check USB cable is data-capable
- Try: `sudo kill -9 $(lsof -t -i /dev/cu.usbserial*)`

## Requirements

- ✅ ESP-IDF 5.x (5.3+ recommended)
- ✅ Python 3.11 (or 3.10/3.12)
- ✅ macOS 10.15+
- ✅ Minino hardware (ESP32-C6)

## Full Documentation

- [BUILD_README.md](BUILD_README.md) - Complete build instructions
- [macOS_flashing_guide.md](../docs/macOS_flashing_guide.md) - Detailed macOS guide
- [MIGRATION_ESP_IDF5.md](MIGRATION_ESP_IDF5.md) - ESP-IDF 5.x migration notes
