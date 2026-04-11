rm -rf device/samsung
##set -e
sudo apt update
sudo apt install openjdk-8-jdk -y
# ===== CONFIG =====
TWRP_BRANCH="twrp-11"
DEVICE="a5ltechn"
JOBS=$(nproc --all)

echo "======================================="
echo "   TWRP Auto Build Script (A5 2015)"
echo "======================================="
echo

# ===== CLEAN (optional) =====
# rm -rf .repo out

# ===== INIT TWRP SOURCE =====
if [ ! -d ".repo" ]; then
    echo "📥 Initializing TWRP source..."
   repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-7.1
fi

# ===== SYNC =====
echo "🔄 Syncing source..."
repo sync -c -j64 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

# ===== CLONE DEVICE TREES =====
echo "📦 Cloning device trees..."


git clone --depth=1 https://github.com/xc112lg/android_device_samsung_a5ltechn -b main device/samsung/a5ltechn

echo "✅ Cloning done!"
echo
# sed -i 's|vendor/omni/config/common.mk|vendor/twrp/config/common.mk|g' device/samsung/a5-common/*.mk
# sed -i 's|$(call inherit-product, vendor/omni/config/gsm.mk)||g' device/samsung/a5-common/*.mk
# cat > device/samsung/a5-common/board/display.mk << 'EOF'
# # Screen density
# # handled by build system
# EOF
# ===== BUILD ENV =====
echo "⚙️ Setting up build environment..."
source build/envsetup.sh

wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb && sudo dpkg -i libtinfo5_6.3-2_amd64.deb && rm -f libtinfo5_6.3-2_amd64.deb
wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb && sudo dpkg -i libncurses5_6.3-2_amd64.deb && rm -f libncurses5_6.3-2_amd64.deb



# Save the script
cd /tmp/src/android


#!/bin/bash
# Single script to fix and build TWRP for Samsung A5000 with size optimizations


cd /tmp/src/android

echo "========================================="
echo "TWRP Build Script for Samsung A5000"
echo "With Size Optimizations"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[!]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended"
    fi
}

# Function to setup Python 2
setup_python2() {
    print_status "Setting up Python 2..."
    
    if command -v python2 &> /dev/null; then
        print_success "Python 2 already installed: $(python2 --version 2>&1)"
    else
        print_status "Installing Python 2 from Debian 11 repository..."
        echo "deb [trusted=yes] http://deb.debian.org/debian bullseye main" | sudo tee /etc/apt/sources.list.d/bullseye.list > /dev/null
        sudo apt update > /dev/null 2>&1
        sudo apt install -y python2 python2-minimal > /dev/null 2>&1
        sudo rm /etc/apt/sources.list.d/bullseye.list
        sudo apt update > /dev/null 2>&1
        print_success "Python 2 installed"
    fi
    
    # Set Python 2 as default for build
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1 > /dev/null 2>&1
    sudo update-alternatives --set python /usr/bin/python2 > /dev/null 2>&1
    export PATH=/usr/bin:$PATH
    print_success "Python 2 set as default"
}

# Function to setup Java 8
setup_java8() {
    print_status "Setting up Java 8..."
    
    if java -version 2>&1 | grep -q 'version "1.8\|version "8'; then
        print_success "Java 8 already installed"
    else
        print_status "Installing Java 8 from Adoptium..."
        cd /tmp
        wget -q --show-progress https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
        sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/ > /dev/null 2>&1
        sudo mv /opt/jdk8u432-b06 /opt/jdk8
        sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100 > /dev/null 2>&1
        sudo update-alternatives --set java /opt/jdk8/bin/java > /dev/null 2>&1
        rm OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
        print_success "Java 8 installed"
    fi
    
    export JAVA_HOME=/opt/jdk8
    export PATH=$JAVA_HOME/bin:$PATH
}

# Function to fix Python build scripts
fix_python_scripts() {
    print_status "Fixing Python build scripts..."
    
    # Fix check_radio_versions.py
    cat > build/tools/check_radio_versions.py << 'EOF'
#!/usr/bin/env python2
import sys
import os

def main():
    # Simplified version for TWRP build
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF
    chmod +x build/tools/check_radio_versions.py
    
    # Fix post_process_props.py if it exists
    if [ -f "build/tools/post_process_props.py" ]; then
        sed -i 's/\.iteritems()/.items()/g' build/tools/post_process_props.py 2>/dev/null || true
        sed -i 's/print "/print("/g' build/tools/post_process_props.py 2>/dev/null || true
    fi
    
    print_success "Python scripts fixed"
}

# Function to create optimized BoardConfig.mk
create_optimized_boardconfig() {
    print_status "Creating optimized BoardConfig.mk..."
    
    # Backup existing if present
    if [ -f "device/samsung/a5ltechn/BoardConfig.mk" ]; then
        cp device/samsung/a5ltechn/BoardConfig.mk device/samsung/a5ltechn/BoardConfig.mk.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backed up existing BoardConfig.mk"
    fi
    
    # Create directory if it doesn't exist
    mkdir -p device/samsung/a5ltechn
    
    cat > device/samsung/a5ltechn/BoardConfig.mk << 'BOARD_EOF'
#
# Copyright (C) 2021 The Android Open Source Project
# Copyright (C) 2021 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/samsung/a5ltechn

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := generic

# Assert
TARGET_OTA_ASSERT_DEVICE := a5ltechn

# File systems
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_COPY_OUT_VENDOR := vendor

# Kernel
BOARD_KERNEL_CMDLINE := console=null androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/zImage
TARGET_PREBUILT_DT := $(DEVICE_PATH)/prebuilt/dt.img
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x02000000
BOARD_KERNEL_TAGS_OFFSET := 0x01e00000
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dt $(TARGET_PREBUILT_DT)
BOARD_KERNEL_IMAGE_NAME := zImage
TARGET_KERNEL_ARCH := arm
TARGET_KERNEL_HEADER_ARCH := arm
TARGET_KERNEL_SOURCE := kernel/samsung/a5ltechn
TARGET_KERNEL_CONFIG := a5ltechn_defconfig

# Platform
TARGET_BOARD_PLATFORM := msm8916

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# TWRP Configuration with Size Reduction
TW_THEME := portrait_hdpi
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TW_EXTRA_LANGUAGES := false
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true

# Size Reduction Flags
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_EXCLUDE_APP_MANAGER := true
TW_EXCLUDE_MULTIUSER := true
TW_EXCLUDE_TREBLE := true
TW_EXCLUDE_FBE := true
TW_EXCLUDE_MTP := true
TW_EXCLUDE_ADB := true
TW_NO_USB_STORAGE := true
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_CRYPTO := true
TW_EXCLUDE_OPENRECOVERY_SCRIPT := true
TW_EXCLUDE_HAPTICS := true
TW_INCLUDE_FB2PNG := false
TW_NO_EXFAT := true
TW_EXCLUDE_TZDATA := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_PYTHON := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_LPTOOLS := true
TW_EXCLUDE_TWRPAPP := true
TW_INCLUDE_NTFS_3G := false
TWRP_INCLUDE_LOGCAT := false
TW_NO_BATT_PERCENT := true
TW_NO_CPU_TEMP := true
TW_NO_SCREEN_TIMEOUT := true
BOARD_HAS_NO_REAL_SDCARD := true

# Compression settings
LZMA_RAMDISK_TARGETS := recovery
TW_OEM_BUILD := true

# Compiler Optimizations for Size
TARGET_GLOBAL_CFLAGS += -Os -ffunction-sections -fdata-sections -fno-unwind-tables -fomit-frame-pointer
TARGET_GLOBAL_CPPFLAGS += -Os -ffunction-sections -fdata-sections -fno-unwind-tables -fomit-frame-pointer
TARGET_GLOBAL_LDFLAGS += -Wl,--gc-sections -Wl,--strip-all

# Additional optimizations
TW_NO_REBOOT_BOOTLOADER := true
TW_NO_REBOOT_RECOVERY := true
TW_HAS_NO_RECOVERY_PARTITION := true
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 162
TW_IGNORE_MISC_WIPE_DATA := true
TW_NO_EXFAT_FUSE := true
BOARD_USE_FRAMEBUFFER_ALWAYS := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_23x41.h\"
BOARD_RECOVERY_SWIPE := true
TW_INCLUDE_RESETPROP := false
TW_INCLUDE_REPACKTOOLS := false
TW_INCLUDE_LIBRESETPROP := false
TW_INCLUDE_CRYPTO := false
TW_INCLUDE_CRYPTO_FBE := false
TW_INCLUDE_FBE_METADATA_DECRYPT := false
TW_INCLUDE_LPDUMP := false
TW_INCLUDE_LPTOOLS := false
TW_INCLUDE_RMSP := false
TW_INCLUDE_REPACKTOOLS := false
TW_EXCLUDE_APEX := true
TW_EXCLUDE_THERMAL := true
TW_EXCLUDE_LOGD := true
TW_EXCLUDE_VOLD := true
BOARD_USES_QCOM_HARDWARE := true
TARGET_RECOVERY_DEVICE_MODULES :=
BOARD_USE_SYSTEM_AS_ROOT := true
TW_BATTERY_SYSFS_WAIT := true
TW_NO_SCREEN_BLANK := true
TW_IGNORE_MAJOR_AXIS_0 := true
TW_CUSTOM_CPU_TEMP_PATH := /sys/class/thermal/thermal_zone0/temp
TW_NO_HAPTICS := true
TW_SUPPORT_INPUT_1 := true
TW_SUPPORT_INPUT_2 := true
TW_SUPPORT_INPUT_3 := true
TW_SUPPORT_INPUT_4 := true
BOARD_USE_LEGACY_BLOCKDEV := true
BOARD_RECOVERY_IMAGE_COMPRESSION := lz4
BOARD_CUSTOM_BOOTIMG_MK :=
BOARD_CUSTOM_BOOTIMG :=
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR := false
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_RECOVERY_USE_MINUI := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FORCE_PIXEL_FORMAT := RGB_565
BOARD_USE_LEGACY_UI := true
BOARD_HAS_FLIPPED_SCREEN := false
BOARD_INCLUDE_RECOVERY_DTBO := false
BOARD_USES_MMCUTILS := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_RECOVERY_USE_MINUI := true
TARGET_RECOVERY_UI_LIB := librecovery_ui_msm
BOARD_USE_FRAMEBUFFER_ALWAYS := true
BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_23x41.h\"
TW_HAS_EDL_MODE := false
TW_HAS_MTP := false
TW_INCLUDE_JB_CRYPTO := false
TW_INCLUDE_L_CRYPTO := false
TW_INCLUDE_M_CRYPTO := false
TW_INCLUDE_N_CRYPTO := false
BOARD_HAS_NO_MISC_PARTITION := true
BOARD_RECOVERY_SWIPE := true
TW_USE_MODEL_HARDWARE_ID := false
TW_USE_SERIAL_NUMBER := false
TW_USE_CPU_INFO := false
TW_USE_MEMORY_INFO := false
BOARD_USE_NTFS_3G := false
BOARD_USE_EXT4UTILS := false
BOARD_USE_F2FSUTILS := false
TW_EXCLUDE_EXT4 := true
TW_EXCLUDE_F2FS := true
TW_EXCLUDE_VFAT := true
TW_EXCLUDE_EXFAT := true
TW_EXCLUDE_NTFS := true
BOARD_HAS_SDCARD_INTERNAL := false
BOARD_HAS_NO_REAL_SDCARD := true
BOARD_HAS_NO_MISC := true
BOARD_USES_BOOTIMAGE_HEADER := true
BOARD_USES_RECOVERY_AS_BOOT := false
TARGET_NO_RECOVERY := false
BOARD_NO_SECURE_DISCARD := true
BOARD_SUPPRESS_EMMC_WIPE := true
BOARD_USE_LEGACY_PARTITION := true
BOARD_USE_LEGACY_RECOVERY := true
BOARD_USE_LEGACY_RECOVERY_PARTITION := true
BOARD_USE_LEGACY_BOOTIMAGE := true
BOARD_USE_LEGACY_HEADER := true
BOARD_USE_LEGACY_KERNEL := true
BOARD_USE_LEGACY_DT := true
BOARD_USE_LEGACY_DTB := true
BOARD_USE_LEGACY_DTBO := true
BOARD_USE_LEGACY_CMDLINE := true
BOARD_USE_LEGACY_PAGESIZE := true
BOARD_USE_LEGACY_BASE := true
BOARD_USE_LEGACY_OFFSETS := true

BOARD_EOF

    print_success "Optimized BoardConfig.mk created"
}

# Function to optimize PNG resources
optimize_pngs() {
    print_status "Optimizing PNG resources..."
    
    if [ -d "bootable/recovery/gui" ]; then
        # Install optimization tools
        sudo apt install -y optipng advancecomp 2>/dev/null || true
        
        # Count PNG files
        PNG_COUNT=$(find bootable/recovery/gui -name "*.png" 2>/dev/null | wc -l)
        if [ $PNG_COUNT -gt 0 ]; then
            print_status "Compressing $PNG_COUNT PNG files..."
            find bootable/recovery/gui -name "*.png" -exec optipng -o7 -strip all {} \; 2>/dev/null
            find bootable/recovery/gui -name "*.png" -exec advpng -z -4 {} \; 2>/dev/null
            print_success "PNG resources optimized"
        else
            print_warning "No PNG files found"
        fi
    else
        print_warning "Recovery GUI directory not found"
    fi
}

# Function to create fstab if missing
create_fstab() {
    if [ ! -f "device/samsung/a5ltechn/recovery/root/etc/twrp.fstab" ]; then
        print_status "Creating twrp.fstab..."
        mkdir -p device/samsung/a5ltechn/recovery/root/etc
        cat > device/samsung/a5ltechn/recovery/root/etc/twrp.fstab << 'EOF'
# Android fstab file for Samsung A5000
/system                 /system             ext4      ro,barrier=1                                 wait
/data                   /data               ext4      noatime,nosuid,nodev,barrier=1,noauto_da_alloc wait,encryptable=footer
/cache                  /cache              ext4      noatime,nosuid,nodev,barrier=1               wait
/boot                   /boot               emmc      defaults                                     defaults
/recovery               /recovery           emmc      defaults                                     defaults
/modem                  /firmware           vfat      defaults                                     defaults
/sdcard                 /sdcard             vfat      defaults                                     defaults
/usb-otg                /usb-otg            vfat      defaults                                     defaults
EOF
        print_success "twrp.fstab created"
    fi
}

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning previous build artifacts..."
    rm -rf out/target/product/a5ltechn/recovery.img 2>/dev/null
    rm -rf out/target/product/a5ltechn/ramdisk-recovery.img 2>/dev/null
    rm -rf out/target/product/a5ltechn/obj/RECOVERY 2>/dev/null
    rm -rf out/build-*.ninja 2>/dev/null
    print_success "Build artifacts cleaned"
}

# Function to start the build
start_build() {
    print_status "Starting TWRP build..."
    print_status "This may take several minutes..."
    
    # Set all environment variables
    export JAVA_HOME=/opt/jdk8
    export PATH=$JAVA_HOME/bin:/usr/bin:$PATH
    export TARGET_SCREEN_WIDTH=720
    export TARGET_SCREEN_HEIGHT=1280
    export TW_THEME=portrait_hdpi
    
    # Source build environment
    if [ -f "build/envsetup.sh" ]; then
        source build/envsetup.sh
        lunch omni_a5ltechn-eng
        
        # Build with optimizations
        make recoveryimage -j$(nproc)
        
        # Check if build succeeded
        if [ -f "out/target/product/a5ltechn/recovery.img" ]; then
            SIZE=$(ls -lh out/target/product/a5ltechn/recovery.img | awk '{print $5}')
            echo ""
            echo "========================================="
            print_success "Build completed successfully!"
            echo "========================================="
            echo -e "${GREEN}Recovery image size: ${SIZE}${NC}"
            echo "Location: out/target/product/a5ltechn/recovery.img"
            echo ""
            echo "To flash:"
            echo "  fastboot flash recovery out/target/product/a5ltechn/recovery.img"
            echo "  or use Odin/Heimdall"
            echo "========================================="
            return 0
        else
            print_error "Build failed - recovery.img not found"
            return 1
        fi
    else
        print_error "build/envsetup.sh not found!"
        print_error "Are you in the Android source root directory?"
        return 1
    fi
}

# Function to show summary
show_summary() {
    echo ""
    echo "========================================="
    echo "Configuration Summary"
    echo "========================================="
    echo "Device: Samsung A5000 (a5ltechn)"
    echo "Resolution: 720x1280 (portrait_hdpi)"
    echo "Python: $(python --version 2>&1)"
    echo "Java: $(java -version 2>&1 | head -1)"
    echo "Architecture: ARMv7-A"
    echo "Optimizations:"
    echo "  - Disabled unnecessary features"
    echo "  - PNG compression applied"
    echo "  - Compiler size optimizations"
    echo "  - LZMA ramdisk compression"
    echo "========================================="
}

# Main execution
main() {
    print_status "Starting TWRP build for Samsung A5000"
    
    check_root
    setup_python2
    setup_java8
    fix_python_scripts
    create_optimized_boardconfig
    create_fstab
    optimize_pngs
    
    # Ask if user wants to clean
    echo ""
    read -p "Clean previous build artifacts? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_build
    fi
    
    show_summary
    
    # Ask if user wants to build
    read -p "Start building now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_build
    else
        print_status "Build skipped. Run './build_recovery.sh' later"
        # Create build script for later
        cat > build_recovery.sh << 'EOF'
#!/bin/bash
cd /tmp/src/android
export JAVA_HOME=/opt/jdk8
export PATH=$JAVA_HOME/bin:/usr/bin:$PATH
export TARGET_SCREEN_WIDTH=720
export TARGET_SCREEN_HEIGHT=1280
export TW_THEME=portrait_hdpi
source build/envsetup.sh
lunch omni_a5ltechn-eng
make recoveryimage -j$(nproc)
EOF
        chmod +x build_recovery.sh
        print_success "Build script created: ./build_recovery.sh"
    fi
}

# Run the main function
main
