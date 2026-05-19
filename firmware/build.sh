#!/bin/bash
# =============================================================================
# Minino Firmware Build Script for macOS
# =============================================================================
# This script automates building, flashing, and monitoring firmware for the
# Electronic Cats Minino hardware (ESP32-C6 based).
#
# ESP-IDF VERSION REQUIREMENT:
# ----------------------------
# This firmware REQUIRES ESP-IDF 5.x (specifically 5.3+ recommended) because:
# 1. The project uses ESP32-C6 which requires ESP-IDF 5.x for full support
# 2. Components like esp-zboss-lib and esp-modbus require ESP-IDF 5.x APIs
# 3. The sdkconfig.defaults uses CONFIG_IDF_TARGET_ESP32C6=y (ESP32-C6 specific)
# 4. Button component (espressif/button ^3.2.0) requires ESP-IDF 5.x
# 5. Zigbee and Thread support need ESP-IDF 5.x framework
#
# ENVIRONMENT SWITCHING:
# ---------------------
# The script detects and activates ESP-IDF 5.x by:
# 1. Checking for ESP-IDF 5.x installation in standard locations
# 2. Validating IDF_PATH points to ESP-IDF 5.x
# 3. Sourcing the correct export.sh to set up the environment
# 4. Verifying Python 3.11 compatibility (required by ESP-IDF 5.x)
#
# USAGE:
#   ./build.sh           - Build the firmware
#   ./build.sh clean     - Clean build artifacts
#   ./build.sh fullclean - Full clean including sdkconfig
#   ./build.sh flash     - Flash to device
#   ./build.sh monitor   - Monitor serial output
#   ./build.sh all       - Build, flash, and monitor
#
# PORT DETECTION:
# --------------
# The script auto-detects the Minino serial port on macOS.
# Override with: PORT=/dev/cu.usbserial-XXXX ./build.sh flash
#
# =============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# =============================================================================
# Configuration
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="$SCRIPT_DIR"
BUILD_DIR="$FIRMWARE_DIR/build"
PROJECT_NAME="minino"
TARGET_CHIP="esp32c6"

# ESP-IDF 5.x installation paths to check (macOS standard locations)
IDF_PATHS_TO_CHECK=(
    "$HOME/esp/esp-idf"                          # Standard ESP-IDF 5.x location
    "$HOME/esp/idf5"                             # Common IDF 5 location
    "$HOME/esp5/esp-idf"                         # Alternative ESP-IDF 5 location
    "/opt/esp-idf"                               # Homebrew ESP-IDF location
    "/opt/espressif/esp-idf"                     # Espressif official location
    "$IDF_PATH"                                  # User-set IDF_PATH
)

# Python version for ESP-IDF 5.x (must be 3.11 preferred, 3.10-3.12 acceptable)
REQUIRED_PYTHON_VERSION="3.11"

# =============================================================================
# Color Output Functions
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status() {
    echo -e "${CYAN}[STATUS]${NC} $1"
}

# =============================================================================
# Python Version Detection
# =============================================================================
# ESP-IDF 5.x requires Python 3.11 (preferred) or compatible version (3.10-3.12)
# ESP-IDF 6.x may require Python 3.12+
# This ensures we use the correct Python version for ESP-IDF 5.x
find_python_for_idf5() {
    print_status "Checking for Python 3.11 (required by ESP-IDF 5.x)..."
    
    # List of Python executables to check (order matters - prefer 3.11)
    local python_execs=(
        "python3.11"
        "python3.12"
        "python3.10"
        "python3"
    )
    
    for python_cmd in "${python_execs[@]}"; do
        if command -v "$python_cmd" &> /dev/null; then
            local version=$("$python_cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
            if [ -n "$version" ]; then
                print_info "Found $python_cmd (Python $version)"
                # Check if version is acceptable for ESP-IDF 5.x (3.10, 3.11, 3.12)
                if [[ "$version" =~ ^3\.(10|11|12)$ ]]; then
                    print_success "Python $version is compatible with ESP-IDF 5.x"
                    echo "$python_cmd"
                    return 0
                fi
            fi
        fi
    done
    
    print_error "No compatible Python version (3.10-3.12) found for ESP-IDF 5.x"
    print_info "Please install Python 3.11: brew install python@3.11"
    return 1
}

# =============================================================================
# ESP-IDF 5.x Detection and Activation
# =============================================================================
# This function locates and activates ESP-IDF 5.x environment
# Priority order:
# 1. Check if already active (IDF_PATH set, idf.py available, ESP-IDF 5.x)
# 2. Try use_idf5 command if available
# 3. Manual detection from standard paths
detect_and_activate_idf5() {
    print_status "Detecting ESP-IDF 5.x installation..."
    
    # Method 1: Check if ESP-IDF 5.x is already active
    if [ -n "$IDF_PATH" ] && [ -f "$IDF_PATH/VERSION" ] && command -v idf.py &> /dev/null; then
        local current_version=$(idf.py --version 2>/dev/null | head -1)
        local major_version="${current_version:10:1}" # Extract major version from "ESP-IDF vX.Y.Z"
        
        if [ "$major_version" = "5" ]; then
            print_success "ESP-IDF 5.x already active: $current_version"
            print_success "IDF_PATH: $IDF_PATH"
            return 0
        elif [ "$major_version" = "6" ]; then
            print_warning "ESP-IDF 6.x is active ($current_version). This project requires ESP-IDF 5.x"
            print_warning "Attempting to switch to ESP-IDF 5.x..."
        fi
    fi
    
    # Method 2: Try use_idf5 command if available
    if command -v use_idf5 &> /dev/null; then
        print_info "Found 'use_idf5' command, executing it to switch to ESP-IDF 5.x..."
        
        # IMPORTANT: use_idf5 must be sourced, not executed as a subprocess
        # because it modifies shell environment variables
        # We need to source it in the current shell context
        
        # First, find where use_idf5 is located
        local use_idf5_path=$(command -v use_idf5)
        
        # Check if it's a shell function or script
        if [ -f "$use_idf5_path" ]; then
            # It's a script, we need to source it
            print_info "Sourcing: $use_idf5_path"
            . "$use_idf5_path"
        else
            # It might be a shell function, try calling it
            print_info "Calling use_idf5 function"
            use_idf5
        fi
        
        # Check if it worked
        if [ -n "$IDF_PATH" ] && [ -f "$IDF_PATH/VERSION" ] && command -v idf.py &> /dev/null; then
            local new_version=$(idf.py --version 2>/dev/null | head -1)
            if [[ "$new_version" == *"ESP-IDF v5"* ]]; then
                print_success "Successfully switched to ESP-IDF 5.x: $new_version"
                return 0
            fi
        fi
        
        print_warning "use_idf5 executed but environment check failed"
        print_info "IDF_PATH: ${IDF_PATH:-'(not set)'}"
    fi
    
    # Method 3: Manual detection from standard paths
    print_info "Attempting manual ESP-IDF 5.x detection..."
    
    local idf_path=""
    local idf_version=""
    local major_version=""
    
    # Check each path in order
    for path in "${IDF_PATHS_TO_CHECK[@]}"; do
        if [ -n "$path" ] && [ -d "$path" ] && [ -f "$path/export.sh" ]; then
            # Try to determine version - either from VERSION file or by testing with idf.py
            major_version=""
            idf_version=""
            
            # Method A: Check VERSION file if it exists
            if [ -f "$path/VERSION" ]; then
                idf_version=$(cat "$path/VERSION" 2>/dev/null | head -1)
                major_version="${idf_version:1:1}"
            fi
            
            # Method B: If no VERSION file, test by sourcing export.sh
            if [ -z "$major_version" ]; then
                local test_output
                test_output=$(bash -c "export IDF_PATH="$path"; . "$path/export.sh" 2>&1 >/dev/null; idf.py --version 2>/dev/null | head -1" 2>/dev/null)
                
                if [[ "$test_output" == *"ESP-IDF v5"* ]]; then
                    major_version="5"
                    idf_version="$test_output"
                elif [[ "$test_output" == *"ESP-IDF v6"* ]]; then
                    major_version="6"
                    idf_version="$test_output"
                fi
            fi
            
            # Check if this is ESP-IDF 5.x
            if [ "$major_version" = "5" ]; then
                idf_path="$path"
                print_info "Found ESP-IDF 5.x at: $idf_path (version: $idf_version)"
                break
            elif [ "$major_version" = "6" ]; then
                print_warning "Found ESP-IDF 6.x at: $path (version: $idf_version) - need 5.x"
            fi
        fi
    done
    
    # Check existing IDF_PATH if not found in standard locations
    if [ -z "$idf_path" ] && [ -n "$IDF_PATH" ] && [ -f "$IDF_PATH/VERSION" ]; then
        idf_version=$(cat "$IDF_PATH/VERSION" 2>/dev/null | head -1)
        local major_version="${idf_version:1:1}"
        
        if [ "$major_version" = "5" ]; then
            idf_path="$IDF_PATH"
            print_info "Using existing IDF_PATH: $idf_path (version: $idf_version)"
        elif [ "$major_version" = "6" ]; then
            print_warning "ESP-IDF 6.x detected at IDF_PATH ($idf_version)"
        fi
    fi
    
    # Final validation
    if [ -z "$idf_path" ]; then
        print_error "ESP-IDF 5.x not found!"
        print_info ""
        print_info "Please run one of these commands first:"
        print_info "  use_idf5              # Switch to ESP-IDF 5.x (if available)"
        print_info "  . ~/esp/esp-idf/export.sh  # Source ESP-IDF environment"
        print_info ""
        print_info "Then run: ./build.sh"
        print_info ""
        print_info "Common installation paths checked:"
        for path in "${IDF_PATHS_TO_CHECK[@]}"; do
            echo "  - $path"
        done
        return 1
    fi
    
    # Export IDF_PATH
    export IDF_PATH="$idf_path"
    print_success "ESP-IDF 5.x located: $idf_version"
    
    return 0
}

# =============================================================================
# Load ESP-IDF Environment
# =============================================================================
# Sources the ESP-IDF environment (export.sh) which sets up:
# - PATH (adds esp-idf tools)
# - IDF_PATH
# - PYTHON path
# - All necessary environment variables
# Note: This sources the export.sh to set up the environment properly
load_idf_environment() {
    # Validate IDF_PATH is set
    if [ -z "$IDF_PATH" ]; then
        print_error "IDF_PATH is not set"
        return 1
    fi
    
    if [ ! -d "$IDF_PATH" ]; then
        print_error "IDF_PATH directory does not exist: $IDF_PATH"
        return 1
    fi
    
    # Check if export.sh exists
    if [ ! -f "$IDF_PATH/export.sh" ]; then
        print_error "export.sh not found in IDF_PATH: $IDF_PATH"
        return 1
    fi
    
    # Check if environment is already fully loaded with ESP-IDF 5.x
    if command -v idf.py &> /dev/null && [ -f "$IDF_PATH/VERSION" ]; then
        local current_idf=$(idf.py --version 2>/dev/null | head -1)
        
        # Check if it's ESP-IDF 5.x
        if [[ "$current_idf" == *"ESP-IDF v5"* ]]; then
            print_success "ESP-IDF 5.x already active: $current_idf"
            return 0
        fi
        
        # If we have ESP-IDF 6.x but detected IDF_PATH points to 5.x, we need to reload
        if [[ "$current_idf" == *"ESP-IDF v6"* ]]; then
            print_warning "ESP-IDF 6.x is active, switching to 5.x from: $IDF_PATH"
        fi
    fi
    
    # Set up Python environment for ESP-IDF 5.x if available
    # ESP-IDF 5.x requires Python 3.11, 3.10, or 3.12
    local idf5_py_env="$HOME/.espressif/python_env/idf5_py3.11_env"
    if [ -d "$idf5_py_env" ] && [ -f "$idf5_py_env/bin/activate" ]; then
        print_info "Activating Python 3.11 environment for ESP-IDF 5.x"
        . "$idf5_py_env/bin/activate"
    fi
    
    # Source export.sh to set up environment
    print_status "Sourcing ESP-IDF environment: $IDF_PATH/export.sh"
    . "$IDF_PATH/export.sh"
    
    # Brief pause to allow environment to settle
    sleep 0.1
    
    # Verify it worked
    if command -v idf.py &> /dev/null; then
        local new_version=$(idf.py --version 2>/dev/null | head -1)
        print_success "ESP-IDF environment loaded: $new_version"
        return 0
    else
        print_warning "idf.py not found in PATH after sourcing export.sh"
        print_info "IDF_PATH is set to: $IDF_PATH"
        print_info "Attempting to continue anyway..."
        return 0
    fi
}

# =============================================================================
# Validate Build Environment
# =============================================================================
validate_environment() {
    print_status "Validating build environment..."
    
    # Check IDF_PATH
    if [ -z "$IDF_PATH" ]; then
        print_error "IDF_PATH is not set"
        return 1
    fi
    
    if [ ! -d "$IDF_PATH" ]; then
        print_error "IDF_PATH directory does not exist: $IDF_PATH"
        return 1
    fi
    
    # Check idf.py is available
    if ! command -v idf.py &> /dev/null; then
        print_error "idf.py not found in PATH"
        print_info "Make sure ESP-IDF export.sh has been sourced"
        return 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found"
        return 1
    fi
    
    print_success "Build environment validated"
    return 0
}

# =============================================================================
# Serial Port Detection (macOS)
# =============================================================================
# Auto-detects USB serial ports on macOS
# Pattern matches common USB-to-serial chips:
# - FTDI: cu.usbserial-*
# - CP210x: cu.usbserial-*
# - CH340/CH341: cu.usbserial-*
# - CDC ACM: cu.usbmodem*
detect_serial_port() {
    if [ -n "$PORT" ]; then
        # User specified PORT via environment variable
        if [ -e "$PORT" ]; then
            print_info "Using specified port: $PORT"
            return 0
        else
            print_warning "Specified port does not exist: $PORT"
        fi
    fi
    
    # Auto-detect: look for USB serial devices
    local ports=()
    for port in /dev/cu.usbserial* /dev/cu.usbmodem*; do
        if [ -e "$port" ]; then
            ports+=("$port")
        fi
    done
    
    if [ ${#ports[@]} -eq 0 ]; then
        print_warning "No USB serial ports detected"
        print_info "Connect Minino via USB and ensure proper drivers are installed"
        print_info "Common drivers: FTDI, CP210x, CH340"
        return 1
    elif [ ${#ports[@]} -eq 1 ]; then
        PORT="${ports[0]}"
        print_info "Auto-detected serial port: $PORT"
        return 0
    else
        print_info "Multiple serial ports found:"
        for port in "${ports[@]}"; do
            echo "  - $port"
        done
        print_info "Set PORT environment variable to use a specific port:"
        echo "  export PORT=${ports[0]}"
        PORT="${ports[0]}"
        print_warning "Using first detected port: $PORT"
        return 0
    fi
}

# =============================================================================
# Build Functions
# =============================================================================

# Set the target chip (ESP32-C6 for Minino)
set_target_chip() {
    print_status "Setting target chip to $TARGET_CHIP..."
    idf.py set-target "$TARGET_CHIP"
    if [ $? -eq 0 ]; then
        print_success "Target chip set to $TARGET_CHIP"
    else
        print_error "Failed to set target chip"
        return 1
    fi
}

# Clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_info "Removed: $BUILD_DIR"
    fi
    
    if [ -d "$FIRMWARE_DIR/managed_components" ]; then
        rm -rf "$FIRMWARE_DIR/managed_components"
        print_info "Removed: managed_components/"
    fi
    
    if [ -f "$FIRMWARE_DIR/sdkconfig" ]; then
        rm "$FIRMWARE_DIR/sdkconfig"
        print_info "Removed: sdkconfig"
    fi
    
    if [ -f "$FIRMWARE_DIR/dependencies.lock" ]; then
        rm "$FIRMWARE_DIR/dependencies.lock"
        print_info "Removed: dependencies.lock"
    fi
    
    print_success "Clean completed"
}

# Full clean (including sdkconfig and all generated files)
full_clean() {
    print_status "Performing full clean..."
    
    clean_build
    
    # Remove all build directories (including profile-specific ones)
    for dir in "$FIRMWARE_DIR"/build-*; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_info "Removed: $dir"
        fi
    done
    
    # Remove all sdkconfig.* except sdkconfig.defaults
    for config in "$FIRMWARE_DIR"/sdkconfig.*; do
        if [ -f "$config" ] && [ "$(basename "$config")" != "sdkconfig.defaults" ]; then
            rm "$config"
            print_info "Removed: $(basename "$config")"
        fi
    done
    
    print_success "Full clean completed"
}

# Build the firmware
build_firmware() {
    print_status "Building firmware for $TARGET_CHIP..."
    print_info "Build directory: $BUILD_DIR"
    
    # Ensure target is set
    if [ ! -f "$FIRMWARE_DIR/sdkconfig" ]; then
        print_info "sdkconfig not found, setting target chip first..."
        set_target_chip
    fi
    
    # Build
    idf.py build
    local build_status=$?
    
    if [ $build_status -eq 0 ]; then
        print_success "Build completed successfully!"
        print_info "Firmware binary: $BUILD_DIR/$PROJECT_NAME.bin"
        print_info "Bootloader: $BUILD_DIR/bootloader/bootloader.bin"
        print_info "Partition table: $BUILD_DIR/partition_table/partition-table.bin"
        return 0
    else
        print_error "Build failed with status: $build_status"
        return $build_status
    fi
}

# Flash firmware to device
flash_firmware() {
    print_status "Flashing firmware..."
    
    # Detect or confirm serial port
    if ! detect_serial_port; then
        print_error "Cannot detect serial port. Please connect Minino via USB."
        print_info "If you know the port, set it: export PORT=/dev/cu.usbserial-XXXX"
        return 1
    fi
    
    # Check if build exists
    if [ ! -f "$BUILD_DIR/$PROJECT_NAME.bin" ]; then
        print_warning "Firmware not built yet. Building first..."
        build_firmware || return $?
    fi
    
    print_status "Flashing to $PORT..."
    idf.py -p "$PORT" flash
    local flash_status=$?
    
    if [ $flash_status -eq 0 ]; then
        print_success "Flash completed!"
    else
        print_error "Flash failed with status: $flash_status"
    fi
    
    return $flash_status
}

# Monitor serial output
monitor_serial() {
    print_status "Starting serial monitor..."
    
    # Detect or confirm serial port
    if ! detect_serial_port; then
        print_error "Cannot detect serial port. Please connect Minino via USB."
        return 1
    fi
    
    print_info "Monitoring port: $PORT"
    print_info "Press Ctrl+] to exit monitor"
    idf.py -p "$PORT" monitor
}

# Erase flash (full chip erase)
erase_flash() {
    print_status "Erasing flash..."
    
    if ! detect_serial_port; then
        print_error "Cannot detect serial port"
        return 1
    fi
    
    print_warning "This will erase the entire flash!"
    idf.py -p "$PORT" erase_flash
    local status=$?
    
    if [ $status -eq 0 ]; then
        print_success "Flash erased"
    else
        print_error "Erase failed"
    fi
    
    return $status
}

# =============================================================================
# Main Entry Point
# =============================================================================
main() {
    echo ""
    print_status "=========================================="
    print_status "Minino Firmware Build Script"
    print_status "Target: $TARGET_CHIP (ESP32-C6)"
    print_status "ESP-IDF: 5.x required"
    print_status "=========================================="
    echo ""
    
    # Step 1: Detect ESP-IDF 5.x
    if ! detect_and_activate_idf5; then
        print_error "ESP-IDF 5.x detection failed"
        print_info ""
        print_info "Try these steps:"
        print_info "1. Run: use_idf5"
        print_info "2. Then run: ./build.sh"
        exit 1
    fi
    
    # Step 2: Load ESP-IDF environment
    if ! load_idf_environment; then
        print_error "Failed to load ESP-IDF environment"
        exit 1
    fi
    
    # Step 3: Validate environment
    if ! validate_environment; then
        print_error "Environment validation failed"
        exit 1
    fi
    
    # Step 4: Process command
    local command="${1:-build}"
    
    case "$command" in
        build|"")
            build_firmware
            ;;
        clean)
            clean_build
            ;;
        fullclean)
            full_clean
            ;;
        flash)
            flash_firmware
            ;;
        monitor)
            monitor_serial
            ;;
        erase)
            erase_flash
            ;;
        all)
            build_firmware && flash_firmware && monitor_serial
            ;;
help|--help|-h)
    echo "Minino Firmware Build Script"
    echo ""
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  (none)    - Build the firmware"
    echo "  build     - Build the firmware"
    echo "  clean     - Clean build artifacts"
    echo "  fullclean - Full clean (including sdkconfig)"
    echo "  flash     - Flash firmware to device"
    echo "  monitor   - Monitor serial output"
    echo "  erase     - Erase flash"
    echo "  all       - Build, flash, and monitor"
    echo "  help      - Show this help"
    echo ""
    echo "ESP-IDF 5.x Setup:"
    echo "  Option 1: use_idf5           # Use use_idf5 command (recommended)"
    echo "  Option 2: . export.sh        # Manually source ESP-IDF environment"
    echo ""
    echo "Environment variables:"
    echo "  PORT      - Serial port (auto-detected if not set)"
    echo "  IDF_PATH  - ESP-IDF installation path"
    echo ""
    echo "Examples:"
    echo "  ./build.sh                        # Build only"
    echo "  ./build.sh flash                  # Flash to device"
    echo "  ./build.sh all                    # Build, flash, monitor"
    echo "  PORT=/dev/cu.usbserial ./build.sh flash"
    echo ""
    ;;
        *)
            print_error "Unknown command: $command"
            echo "Use './build.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
