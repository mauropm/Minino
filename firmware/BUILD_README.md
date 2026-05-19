# Minino Firmware Build Instructions

Quick start guide for building and flashing Minino firmware on macOS.

## Requirements

- **ESP-IDF 5.x** (5.3+ recommended) - **ESP-IDF 6.x is NOT supported**
- **Python 3.11** (or 3.10/3.12)
- **macOS** (Intel or Apple Silicon)
- **Minino hardware** (ESP32-C6 based)

## Quick Start

### Option 1: Using use_idf5 (Recommended if available)

If you have the `use_idf5` command installed:

```bash
# Switch to ESP-IDF 5.x environment
use_idf5

# Build firmware
cd /path/to/minino/firmware
./build.sh

# Build and flash
./build.sh flash
```

### Option 2: Manual Setup

#### 1. Install Dependencies (First Time Only)

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python 3.11
brew install python@3.11

# Install ESP-IDF 5.3.2
mkdir -p ~/esp
cd ~/esp
git clone -b v5.3.2 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
./install.sh esp32c6
```

#### 2. Set Up Environment

```bash
# Source ESP-IDF environment
. ~/esp/esp-idf/export.sh
```

#### 3. Build Firmware

```bash
cd /path/to/minino/firmware

# Build
./build.sh

# Or build and flash
./build.sh flash

# Or build, flash, and monitor
./build.sh all
```

## Build Script Commands

| Command | Description |
|---------|-------------|
| `./build.sh` | Build firmware |
| `./build.sh clean` | Clean build artifacts |
| `./build.sh fullclean` | Full clean (including sdkconfig) |
| `./build.sh flash` | Flash to device |
| `./build.sh monitor` | Monitor serial output |
| `./build.sh erase` | Erase flash |
| `./build.sh all` | Build + Flash + Monitor |
| `./build.sh help` | Show help |

## Manual Build Commands

If you prefer manual control:

```bash
# Set target chip (first time only)
idf.py set-target esp32c6

# Build
idf.py build

# Flash (auto-detects port)
idf.py flash

# Flash to specific port
idf.py -p /dev/cu.usbserial-XXXX flash

# Monitor
idf.py -p /dev/cu.usbserial-XXXX monitor

# Erase flash
idf.py -p /dev/cu.usbserial-XXXX erase_flash
```

## Configuration Profiles

The project supports multiple build configurations:

| Profile | Description |
|---------|-------------|
| `minino` | Standard Minino configuration |
| `bsides` | BSides conference variant |
| `dragonjar` | DragonJar conference variant |
| `ekoparty` | Ekoparty conference variant |
| `bugcon` | BugCon conference variant |
| `bsseattle` | BSides Seattle variant |

To build with a specific profile:

```bash
idf.py @profiles/minino build
```

## Target Hardware

- **Chip**: ESP32-C6
- **Flash**: 8MB
- **Partition**: OTA-capable (partitions.csv)

## Troubleshooting

### No Serial Port Detected

```bash
# List available ports
ls -l /dev/cu.*

# Common ports:
# FTDI:    /dev/cu.usbserial-XXXX
# CP210x:  /dev/cu.usbserial-XXXX
# CH340:   /dev/cu.usbserial-XXXX
```

### Build Fails

```bash
# Clean and rebuild
./build.sh fullclean
./build.sh

# Check ESP-IDF version
idf.py --version  # Should be 5.x

# Check Python version
python --version  # Should be 3.10-3.12
```

### Flash Fails

1. Hold BOOT button while connecting USB
2. Try: `idf.py -p /dev/cu.usbserial-XXXX flash`
3. Check USB cable (must be data-capable)

## Documentation

- [macOS Flashing Guide](../docs/macOS_flashing_guide.md) - Detailed macOS instructions
- [MIGRATION_ESP_IDF5.md](MIGRATION_ESP_IDF5.md) - ESP-IDF 5.x migration notes
- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/en/v5.3/)

## Build Output

After successful build:

```
build/
├── minino.bin              # Main firmware
├── bootloader/
│   └── bootloader.bin      # Bootloader
├── partition_table/
│   └── partition-table.bin # Partition table
└── ota_data_initial.bin    # OTA data
```

## Version Information

- **Firmware Version**: 0.1.0 (from sdkconfig.version)
- **ESP-IDF**: 5.3.x
- **Python**: 3.11.x
- **Target**: esp32c6
