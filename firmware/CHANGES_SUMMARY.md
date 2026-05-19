# Build Script Fixes Summary

## Problem
The `build.sh` script was failing to detect ESP-IDF 5.x even when:
1. ESP-IDF 5.x was installed at `~/esp/idf5`
2. The `use_idf5` command was available
3. User ran `use_idf5` before running `./build.sh`

## Root Causes

1. **Missing Path**: The script wasn't checking `~/esp/idf5` which is a common installation location
2. **Subprocess Issue**: When `use_idf5` is run in the parent shell, the environment doesn't carry over to the script's subprocess
3. **Detection Logic**: The script was trying to call `use_idf5` as a subprocess instead of sourcing it

## Changes Made

### 1. Added Missing IDF Path
```bash
IDF_PATHS_TO_CHECK=(
    "$HOME/esp/esp-idf"
    "$HOME/esp/idf5"              # <-- Added this
    "$HOME/esp5/esp-idf"
    "/opt/esp-idf"
    "/opt/espressif/esp-idf"
    "$IDF_PATH"
)
```

### 2. Improved Detection Logic
The script now:
- Checks if ESP-IDF 5.x is **already active** (idf.py available + VERSION file)
- Tries to **source** `use_idf5` if it's a script (not just call it)
- Falls back to manual path detection
- Sources `export.sh` to properly set up the environment

### 3. Better Error Messages
Now provides clear instructions:
```
Please run one of these commands first:
  use_idf5              # Switch to ESP-IDF 5.x (if available)
  . ~/esp/esp-idf/export.sh  # Source ESP-IDF environment

Then run: ./build.sh
```

### 4. Fixed Syntax Errors
- Removed duplicate code blocks
- Fixed mismatched if/else statements
- Ensured proper function returns

## How It Works Now

### Scenario 1: User runs `use_idf5` first (Recommended)
```bash
use_idf5        # Sets up environment in current shell
./build.sh      # Detects IDF_PATH is already set, uses it
```

### Scenario 2: Script auto-detects installation
```bash
./build.sh      # Finds ~/esp/idf5, sources export.sh automatically
```

### Scenario 3: User has multiple IDF versions
```bash
# Script prioritizes:
# 1. Already-active ESP-IDF 5.x (if idf.py in PATH)
# 2. use_idf5 command (sources it)
# 3. Manual path detection (~/esp/idf5, etc.)
```

## Testing

To test the fixed script:

```bash
# Test 1: Auto-detection (no use_idf5)
cd /path/to/minino/firmware
./build.sh build

# Test 2: With use_idf5
use_idf5
./build.sh build

# Test 3: Manual path
export IDF_PATH=~/esp/idf5
./build.sh build
```

## Files Modified

1. **build.sh**
   - Fixed ESP-IDF detection logic
   - Added `~/esp/idf5` to search paths
   - Improved environment loading
   - Better error messages
   - Fixed syntax errors

2. **BUILD_README.md**
   - Added `use_idf5` as recommended method
   - Updated quick start instructions

3. **QUICKSTART.md** (new)
   - Quick reference card

4. **Help text in build.sh**
   - Added `use_idf5` usage examples

## Verification

Run syntax check:
```bash
bash -n build.sh  # Should show no errors
```

Test detection:
```bash
./build.sh build  # Should detect ESP-IDF 5.x and build
```

Check version:
```bash
idf.py --version  # Should show ESP-IDF v5.x.x
```

## Next Steps

1. Test with: `./build.sh clean && ./build.sh build`
2. If it works, test flash: `./build.sh flash`
3. Verify monitor: `./build.sh monitor`
