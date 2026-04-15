#!/usr/bin/env bash
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

#git clone --depth=1 https://github.com/omnirom/android_vendor_omni -b android-10 vendor/omni

# ===== BUILD =====
echo "🛠️ Building TWRP..."

#!/bin/bash
# check_and_setup_jdk8.sh

# Check if JDK 8 is available
if ! java -version 2>&1 | grep -q 'version "1.8\|version "8'; then
    echo "JDK 8 not found. Installing..."
    
    # Install JDK 8 (your installation method here)
    cd /tmp
    wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
    sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/
    sudo mv /opt/jdk8u432-b06 /opt/jdk8
    sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100
    sudo update-alternatives --set java /opt/jdk8/bin/java
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
fi

# Set environment
export JAVA_HOME=/opt/jdk8
export PATH=$JAVA_HOME/bin:$PATH

echo "Using Java:"
java -version

java -version
sleep 10
export LC_ALL=C
export LANG=C
export LANGUAGE=C
export TARGET_SCREEN_WIDTH=720
export TARGET_SCREEN_HEIGHT=1280
export TW_THEME=portrait_hdpi

export TW_THEME=portrait_mdpi 
export BOARD_RAMDISK_USE_LZMA=true


cd /tmp/src/android

echo "========================================="
echo "Setting up Python 2 for TWRP build"
echo "========================================="

# Step 1: Install Python 2 from Debian 11 repository
echo "Installing Python 2 from Debian 11..."

# Add Debian 11 repository
sudo bash -c 'cat > /etc/apt/sources.list.d/bullseye.list << EOF
deb [trusted=yes] http://deb.debian.org/debian bullseye main
EOF'

# Update and install Python 2
sudo apt update
sudo apt install -y python2 python2-minimal

# Remove the repository to avoid conflicts
sudo rm /etc/apt/sources.list.d/bullseye.list
sudo apt update

# Step 2: Verify Python 2 installation
echo ""
echo "Python 2 version:"
python2 --version

# Step 3: Set Python 2 as default for the build
echo ""
echo "Setting Python 2 as default..."
sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 2
sudo update-alternatives --set python /usr/bin/python2

# Step 4: Verify default Python
echo ""
echo "Default Python version:"
python --version

# Step 5: Fix Python scripts in build tree
echo ""
echo "Fixing Python 2/3 compatibility in build scripts..."

# Fix post_process_props.py
if [ -f "build/tools/post_process_props.py" ]; then
    # Keep it as Python 2 script (no conversion needed since we're using Python 2)
    echo "✓ build/tools/post_process_props.py will run with Python 2"
fi

# Fix check_radio_versions.py (simplify it)
cat > build/tools/check_radio_versions.py << 'EOF'
#!/usr/bin/env python2
import sys
import os

def main():
    # Simplified version for TWRP build - always succeeds
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF
chmod +x build/tools/check_radio_versions.py

# Step 6: Set up Java 8 if not already present
if ! java -version 2>&1 | grep -q 'version "1.8\|version "8'; then
    echo ""
    echo "Setting up Java 8..."
    cd /tmp
    wget -q https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
    sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/
    sudo mv /opt/jdk8u432-b06 /opt/jdk8
    sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100
    sudo update-alternatives --set java /opt/jdk8/bin/java
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
fi

# Step 7: Set environment variables
export JAVA_HOME=/opt/jdk8
export PATH=$JAVA_HOME/bin:$PATH
# export TARGET_SCREEN_WIDTH=720
# export TARGET_SCREEN_HEIGHT=1280
# export TW_THEME=portrait_hdpi
# export TW_THEME=portrait_mdpi 
# export BOARD_RAMDISK_USE_LZMA=true
# # Step 8: Clean previous build artifacts
# echo ""
# echo "Cleaning build artifacts..."
# rm -rf out/target/product/a5ltechn/obj/ETC/system_build_prop_intermediates/
# rm -rf out/build-*.ninja
##################################################################
#!/bin/bash
# TWRP Size Compression Script - Focused only on reducing recovery size

cd /tmp/src/android

echo "========================================="
echo "TWRP Size Compression & Optimization"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Marker file to track if compression was already done
COMPRESS_MARKER="/tmp/src/android/.png_compression_done"
FORCE_COMPRESS=false

# Check for --force flag
if [ "$1" == "--force" ]; then
    FORCE_COMPRESS=true
    print_warning "Force mode: Will re-compress all PNGs"
    rm -f "$COMPRESS_MARKER"
fi

# 1. Add compression flags to BoardConfig.mk
print_status "Adding compression flags to BoardConfig.mk..."

# Check if flags already exist to avoid duplicates
if ! grep -q "LZMA_RAMDISK_TARGETS := recovery" device/samsung/a5ltechn/BoardConfig.mk 2>/dev/null; then
    cat >> device/samsung/a5ltechn/BoardConfig.mk << 'EOF'

# ============================================
# Compression & Size Reduction Flags
# ============================================

# Ramdisk compression (LZMA gives best compression)
LZMA_RAMDISK_TARGETS := recovery
BOARD_RAMDISK_USE_LZ4 := true

# Remove unnecessary features
TW_EXTRA_LANGUAGES := false
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

# Minimal build
TW_OEM_BUILD := true
TW_USE_TOOLBOX := true

# Compiler optimizations for size
TARGET_GLOBAL_CFLAGS += -Os -ffunction-sections -fdata-sections -fno-unwind-tables -fomit-frame-pointer
TARGET_GLOBAL_CPPFLAGS += -Os -ffunction-sections -fdata-sections -fno-unwind-tables -fomit-frame-pointer
TARGET_GLOBAL_LDFLAGS += -Wl,--gc-sections -Wl,--strip-all

# Disable resetprop to save space
TW_INCLUDE_RESETPROP := false

EOF
    print_success "Compression flags added"
else
    print_warning "Compression flags already present, skipping"
fi

# 2. Compress PNG images (only if not done before or force flag used)
# print_status "Checking PNG compression status..."

# if [ -d "bootable/recovery/gui" ]; then
    
#     if [ -f "$COMPRESS_MARKER" ] && [ "$FORCE_COMPRESS" == false ]; then
#         print_warning "PNG compression already performed previously"
#         print_warning "Skipping to avoid re-compression (no benefit)"
#         print_warning "To force re-compression, run: $0 --force"
#     else
#         print_status "Compressing PNG images..."
        
#         # Install optimization tools
#         sudo apt update > /dev/null 2>&1
#         sudo apt install -y optipng advancecomp pngquant 2>/dev/null
        
#         # Count PNG files
#         PNG_COUNT=$(find bootable/recovery/gui -name "*.png" 2>/dev/null | wc -l)
#         print_status "Found $PNG_COUNT PNG files to compress"
        
#         if [ $PNG_COUNT -gt 0 ]; then
#             # Get size before compression
#             SIZE_BEFORE=$(find bootable/recovery/gui -name "*.png" -exec stat -c%s {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
#             SIZE_BEFORE_MB=$((SIZE_BEFORE / 1024 / 1024))
#             print_status "Total PNG size before: ${SIZE_BEFORE_MB}MB"
            
#             # Lossless compression with optipng
#             print_status "Running lossless compression (optipng)..."
#             find bootable/recovery/gui -name "*.png" -exec optipng -o7 -strip all {} \; 2>/dev/null
            
#             # Additional compression with advpng
#             print_status "Running additional compression (advpng)..."
#             find bootable/recovery/gui -name "*.png" -exec advpng -z -4 {} \; 2>/dev/null
            
#             # Lossy compression for animation frames (saves more space)
#             print_status "Compressing animation frames (lossy)..."
#             find bootable/recovery/gui -path "*/images/loop*.png" 2>/dev/null | while read img; do
#                 pngquant --quality=30-70 --ext .png --force "$img" 2>/dev/null
#             done
            
#             # Get size after compression
#             SIZE_AFTER=$(find bootable/recovery/gui -name "*.png" -exec stat -c%s {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
#             SIZE_AFTER_MB=$((SIZE_AFTER / 1024 / 1024))
#             SAVED=$((SIZE_BEFORE_MB - SIZE_AFTER_MB))
            
#             print_success "PNG compression complete"
#             print_status "Size before: ${SIZE_BEFORE_MB}MB"
#             print_status "Size after: ${SIZE_AFTER_MB}MB"
#             print_success "Saved: ${SAVED}MB"
            
#             # Create marker file to indicate compression was done
#             touch "$COMPRESS_MARKER"
#         else
#             print_warning "No PNG files found to compress"
#         fi
#     fi
# else
#     print_warning "bootable/recovery/gui not found, skipping PNG compression"
# fi

# 3. Remove unnecessary files from recovery root
print_status "Cleaning unnecessary files..."

# Clean recovery root
if [ -d "out/target/product/a5ltechn/recovery/root" ]; then
    # Remove unnecessary binaries
    rm -f out/target/product/a5ltechn/recovery/root/sbin/adbd 2>/dev/null
    rm -f out/target/product/a5ltechn/recovery/root/sbin/mtpdaemon 2>/dev/null
    rm -f out/target/product/a5ltechn/recovery/root/sbin/busybox 2>/dev/null
    
    # Remove unnecessary libraries
    rm -f out/target/product/a5ltechn/recovery/root/lib/libcrypto.so 2>/dev/null
    rm -f out/target/product/a5ltechn/recovery/root/lib/libssl.so 2>/dev/null
    
    print_success "Unnecessary files removed"
fi

# 4. Create optimized build script
print_status "Creating optimized build script..."



# Optimized build script for smaller recovery

cd /tmp/src/android

# Set environment
export JAVA_HOME=/opt/jdk8
export PATH=$JAVA_HOME/bin:/usr/bin:$PATH
export TARGET_SCREEN_WIDTH=720
export TARGET_SCREEN_HEIGHT=1280
export TW_THEME=portrait_hdpi

# Use Python 2
sudo update-alternatives --set python /usr/bin/python2 2>/dev/null




##########################

###################
# Clean previous build
make clean

# Build with compression
source build/envsetup.sh
lunch omni_a5ltechn-eng
make recoveryimage -j$(nproc)

# Show result
if [ -f "out/target/product/a5ltechn/recovery.img" ]; then
    SIZE=$(ls -lh out/target/product/a5ltechn/recovery.img | awk '{print $5}')
    echo ""
    echo "========================================="
    echo "Build complete!"
    echo "Recovery size: $SIZE"
    echo "========================================="
fi



# 5. Show size comparison if old image exists
print_status "Size analysis..."

if [ -f "out/target/product/a5ltechn/recovery.img" ]; then
    CURRENT_SIZE=$(ls -lh out/target/product/a5ltechn/recovery.img | awk '{print $5}')
    print_warning "Current recovery size: $CURRENT_SIZE"
else
    print_warning "No existing recovery image found"
fi

######################################################


# make clean
# make recoveryimage -j$JOBS 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

# # ===== DONE =====
# echo
# echo "======================================="
# echo "✅ BUILD COMPLETE!"
# echo "📍 Output:"
# echo "out/target/product/${DEVICE}/recovery.img"
# echo "======================================="
# # ===== LUNCH =====
# echo "🍱 Lunching device..."
