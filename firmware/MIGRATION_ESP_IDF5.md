# ESP-IDF 5.x Migration Notes for Minino Firmware

This document describes the migration considerations and changes for building Minino firmware with ESP-IDF 5.x.

## Why ESP-IDF 5.x is Required

The Minino firmware **requires ESP-IDF 5.x** (specifically 5.3+) for the following reasons:

### 1. ESP32-C6 Support
- The Minino hardware uses the ESP32-C6 chip
- Full ESP32-C6 support was introduced in ESP-IDF 5.0
- ESP-IDF 6.x has breaking changes that may affect compatibility

### 2. Component Dependencies
The following components require ESP-IDF 5.x APIs:
- `espressif/button` v3.2.0+ - Uses ESP-IDF 5.x GPIO button API
- `espressif/esp-modbus` v2.0.2+ - Requires ESP-IDF 5.x modbus framework
- `esp-zboss-lib` - Zigbee library requires ESP-IDF 5.x
- IEEE 802.15.4 stack - Thread/Zigbee support in 5.x

### 3. Configuration Compatibility
The `sdkconfig.defaults` uses ESP-IDF 5.x specific settings:
```
CONFIG_IDF_TARGET="esp32c6"
CONFIG_IDF_TARGET_ESP32C6=y
CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG=y
```

## ESP-IDF 5.x vs 6.x Key Differences

### API Changes Affecting This Project

| Feature | ESP-IDF 5.x | ESP-IDF 6.x | Impact |
|---------|-------------|-------------|--------|
| Console | `esp_console` v2 | `esp_console` v3 | Medium |
| Button API | `button_adc` v2 | `button_adc` v3 | Low |
| mbedTLS | Built-in | External component | High |
| Zigbee | esp-zboss-lib 1.x | esp-zboss-lib 2.x | High |
| Python | 3.10-3.12 | 3.12+ | Medium |

### Deprecated APIs in ESP-IDF 5.x (Removed in 6.x)

The following APIs are deprecated in 5.x and may be removed in 6.x:

1. **RTC GPIO API** (used in sleep_mode.c)
   - Old: `rtc_gpio_pullup_en()`
   - Old: `rtc_gpio_hold_en()`
   - Status: Still works in 5.x, may need update for 6.x

2. **ESP Console** 
   - Already using v2 API in sdkconfig
   - Compatible with 5.x

3. **FreeRTOS API**
   - Project uses standard FreeRTOS APIs
   - Compatible with both 5.x and 6.x

## Current Codebase Status

### Compatible Components ✅

The following components are confirmed compatible with ESP-IDF 5.x:

- ✅ Main application (`main.c`)
- ✅ Sleep mode module (using `rtc_gpio` - still valid in 5.x)
- ✅ Timer API (`esp_timer.h`)
- ✅ Logging (`esp_log.h`)
- ✅ Console component
- ✅ Button component (espressif/button ^3.2.0)
- ✅ ESP-Modbus (espressif/esp-modbus ^2.0.2)
- ✅ Zigbee console (esp-zigbee-console)
- ✅ IEEE 802.15.4 stack
- ✅ OpenThread

### Potential Issues ⚠️

1. **RTC GPIO in sleep_mode.c** (Lines 31, 33)
   ```c
   rtc_gpio_pullup_en(GPIO_NUM_1);
   rtc_gpio_hold_en(GPIO_NUM_1);
   ```
   - Status: Works in ESP-IDF 5.x
   - For 6.x: May need to use `rtc_gpio_config()` API
   - Action: Monitor for deprecation warnings

2. **Partition Table**
   - Current: `partitions.csv` with OTA support
   - Compatible with both 5.x and 6.x
   - No changes needed

3. **Custom Components**
   - All custom components in `components/` directory
   - Use standard ESP-IDF 5.x APIs
   - No migration needed

## Build System Compatibility

### CMakeLists.txt
The project uses CMake (required for ESP-IDF 5.x):
```cmake
cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(minino)
```
✅ Compatible with ESP-IDF 5.x

### Component Manager
Uses `idf_component.yml`:
```yaml
dependencies:
  espressif/button: ^3.2.0
  idf:
    version: '>=4.1.0'  # Should be '>=5.0.0' for clarity
```

**Recommended update:**
```yaml
dependencies:
  espressif/button: ^3.2.0
  idf:
    version: '>=5.0.0'  # Explicit ESP-IDF 5.x requirement
```

## Migration Checklist

### For ESP-IDF 5.x Installation ✅

- [x] Install Python 3.11 (or 3.10/3.12)
- [x] Install ESP-IDF 5.3.x
- [x] Set up virtual environment
- [x] Install ESP32-C6 target support
- [x] Configure environment variables

### For Building ✅

- [x] Use `build.sh` script (automates ESP-IDF 5.x detection)
- [x] Or manually: `. $IDF_PATH/export.sh`
- [x] Run `idf.py set-target esp32c6`
- [x] Build with `idf.py build`

### For Migration to 6.x (Future) ⚠️

If migrating to ESP-IDF 6.x in the future:

- [ ] Update `idf_component.yml` to specify ESP-IDF 6.x compatible versions
- [ ] Replace `rtc_gpio_*` calls with new API
- [ ] Update mbedTLS usage (now external component)
- [ ] Test all components thoroughly
- [ ] Update partition table if needed
- [ ] Verify Zigbee/Thread compatibility
- [ ] Update Python to 3.12+

## Testing Performed

The following has been verified for ESP-IDF 5.x:

✅ Build system detects ESP-IDF 5.x correctly
✅ Target chip set to ESP32-C6
✅ All components compile without errors
✅ Partition table is valid
✅ sdkconfig.defaults compatible
✅ Python version validation works
✅ Build script environment switching functional

## Known Limitations

1. **ESP-IDF 6.x Compatibility**: Not tested and not recommended
2. **Python Version**: Must be 3.10-3.12 for ESP-IDF 5.x
3. **mbedTLS Configuration**: Some options may need adjustment for 6.x

## References

- [ESP-IDF 5.x Release Notes](https://docs.espressif.com/projects/esp-idf/en/v5.3/esp32c6/release-notes.html)
- [ESP-IDF 5.x Migration Guide](https://docs.espressif.com/projects/esp-idf/en/v5.3/esp32c6/migration-guides.html)
- [ESP32-C6 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32c6_teical_rm.pdf)
- [ESP-IDF Version Policy](https://docs.espressif.com/projects/esp-idf/en/latest/esp32c6/versions.html)

## Support

For ESP-IDF 5.x specific issues:
- GitHub: https://github.com/espressif/esp-idf/issues
- Forum: https://www.esp32.com/viewforum.php?f=42

For Minino-specific issues:
- Check project documentation
- Review hardware documentation
