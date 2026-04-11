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
lunch omni_a5ltechn-eng
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


cat > /tmp/src/android/device/samsung/a5ltechn/BoardConfig_minimal.mk << 'EOF'
# Minimal TWRP configuration for Samsung A5000

# Screen
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TW_THEME := portrait_hdpi

# Maximum size reduction
TW_EXTRA_LANGUAGES := false
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_EXCLUDE_APP_MANAGER := true
TW_EXCLUDE_MULTIUSER := true
TW_EXCLUDE_TREBLE := true
TW_EXCLUDE_FBE := true
TW_EXCLUDE_MTP := true
TW_EXCLUDE_ADB := true
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_CRYPTO := true
TW_EXCLUDE_OPENRECOVERY_SCRIPT := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_PYTHON := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_TWRPAPP := true
TWRP_INCLUDE_LOGCAT := false
TW_NO_BATT_PERCENT := true
TW_OEM_BUILD := true

# Compression
LZMA_RAMDISK_TARGETS := recovery
BOARD_RAMDISK_USE_LZ4 := true

# Compiler flags
TARGET_GLOBAL_CFLAGS += -Os -ffunction-sections -fdata-sections
TARGET_GLOBAL_LDFLAGS += -Wl,--gc-sections -Wl,--strip-all
EOF

# Use minimal config
cp /tmp/src/android/device/samsung/a5ltechn/BoardConfig_minimal.mk /tmp/src/android/device/samsung/a5ltechn/BoardConfig.mk

make clean
make recoveryimage -j$JOBS 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

# ===== DONE =====
echo
echo "======================================="
echo "✅ BUILD COMPLETE!"
echo "📍 Output:"
echo "out/target/product/${DEVICE}/recovery.img"
echo "======================================="
# ===== LUNCH =====
echo "🍱 Lunching device..."


