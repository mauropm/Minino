# Testing the Fixed Build Script

## Quick Test

Run this command to test if the script can now detect ESP-IDF 5.x:

```bash
cd /Users/mauro/Documents/Code/Minino/firmware
./build.sh build
```

## Expected Output

If successful, you should see:

```
[STATUS] ==========================================
[STATUS] Minino Firmware Build Script
[STATUS] Target: esp32c6 (ESP32-C6)
[STATUS] ESP-IDF: 5.x required
[STATUS] ==========================================

[STATUS] Detecting ESP-IDF 5.x installation...
[INFO] Found ESP-IDF 5.x at: /Users/mauro/esp/idf5
[SUCCESS] ESP-IDF 5.x located: (version)
[SUCCESS] ESP-IDF 5.x environment loaded: ESP-IDF v5.x.x

[STATUS] Validating build environment...
[SUCCESS] Build environment validated

[STATUS] Building firmware for esp32c6...
...
```

## If It Still Fails

### Test 1: Check if IDF path is detected

```bash
cd /Users/mauro/Documents/Code/Minino/firmware
bash -c 'path="$HOME/esp/idf5"; if [ -d "$path" ] && [ -f "$path/export.sh" ]; then echo "✓ Path exists: $path"; else echo "✗ Path not found"; fi'
```

### Test 2: Manually source export.sh

```bash
cd /Users/mauro/Documents/Code/Minino/firmware
. ~/esp/idf5/export.sh
idf.py --version
```

This should show: `ESP-IDF v5.x.x`

### Test 3: Use use_idf5 first

```bash
use_idf5
cd /Users/mauro/Documents/Code/Minino/firmware
./build.sh build
```

### Test 4: Set IDF_PATH manually

```bash
export IDF_PATH=$HOME/esp/idf5
cd /Users/mauro/Documents/Code/Minino/firmware
./build.sh build
```

## Debug Mode

To see what the script is detecting, run:

```bash
cd /Users/mauro/Documents/Code/Minino/firmware
bash -x ./build.sh build 2>&1 | head -50
```

This will show you each step the script takes.

## Common Issues

### Issue 1: "ESP-IDF 5.x not found!"

**Solution**: The script couldn't find ESP-IDF in standard paths.

Try:
```bash
export IDF_PATH=$HOME/esp/idf5
./build.sh build
```

### Issue 2: "idf.py not found"

**Solution**: export.sh didn't add idf.py to PATH.

Try:
```bash
. $HOME/esp/idf5/export.sh
which idf.py
```

If that doesn't work, check:
```bash
ls $HOME/esp/idf5/tools/idf.py
```

### Issue 3: "Python version mismatch"

**Solution**: ESP-IDF 5.x needs Python 3.11

Check:
```bash
python3 --version
```

Should be: Python 3.11.x (or 3.10/3.12)

## Success Criteria

The build is successful if:
- [x] Script detects ESP-IDF 5.x
- [x] Script sources export.sh successfully
- [x] idf.py becomes available
- [x] Build completes without errors
- [x] Build artifacts appear in `build/` directory

## Next Steps After Successful Build

1. **Flash to device**:
   ```bash
   ./build.sh flash
   ```

2. **Monitor output**:
   ```bash
   ./build.sh monitor
   ```

3. **Full workflow**:
   ```bash
   ./build.sh all
   ```

## Report Issues

If you still have problems, provide:
1. Output from: `./build.sh build`
2. ESP-IDF version: `idf.py --version`
3. Python version: `python3 --version`
4. IDF_PATH value: `echo $IDF_PATH`
