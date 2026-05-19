# Minino Firmware - Command Reference

Quick reference card for all build and flash commands.

## Build Commands

```bash
# Build firmware
./build.sh

# Build with clean
./build.sh clean && ./build.sh

# Full clean rebuild
./build.sh fullclean && ./build.sh

# Flash to device
./build.sh flash

# Build, flash, and monitor
./build.sh all

# Monitor serial output
./build.sh monitor

# Erase flash
./build.sh erase

# Show help
./build.sh help
```

## Manual IDF Commands

```bash
# Set target chip (first time only)
idf.py set-target esp32c6

# Build
idf.py build

# Flash (auto-detects port)
idf.py flash

# Flash to specific port
idf.py -p /dev/cu.usbserial-XXXX flash

# Monitor serial
idf.py -p /dev/cu.usbserial-XXXX monitor

# Flash and monitor
idf.py -p /dev/cu.usbserial-XXXX flash monitor

# Erase flash
idf.py -p /dev/cu.usbserial-XXXX erase_flash

# Build with specific profile
idf.py @profiles/minino build
```

## Serial Port Detection

```bash
# List all serial ports
ls -l /dev/cu.*

# Find USB serial devices
ls /dev/cu.usbserial* 2>/dev/null
ls /dev/cu.usbmodem* 2>/dev/null

# Check what's connected
system_profiler SPUSBDataType
```

## Environment Setup

```bash
# Source ESP-IDF environment
. $IDF_PATH/export.sh

# Or specific path
. ~/esp/esp-idf/export.sh

# Verify installation
idf.py --version
python --version
```

## Port Override

```bash
# Set specific port
export PORT=/dev/cu.usbserial-1234
./build.sh flash

# Or inline
PORT=/dev/cu.usbserial-1234 ./build.sh flash
```

## Common Port Names

| Chip | Pattern | Example |
|------|---------|---------|
| FTDI | `/dev/cu.usbserial-*` | `/dev/cu.usbserial-A1028X` |
| CP210x | `/dev/cu.usbserial-*` | `/dev/cu.usbserial-0001` |
| CH340 | `/dev/cu.usbserial-*` | `/dev/cu.usbserial-140` |
| CDC ACM | `/dev/cu.usbmodem*` | `/dev/cu.usbmodem1234` |

## Troubleshooting