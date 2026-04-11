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
# setup_jdk8_debian13.sh

set -e

echo "Setting up JDK 8 on Debian 13 (Trixie)..."

# Method 2: Install from Adoptium (Recommended)
echo "Downloading JDK 8 from Adoptium..."
cd /tmp
wget -q --show-progress https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz

echo "Extracting to /opt/jdk8..."
sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/
sudo mv /opt/jdk8u432-b06 /opt/jdk8

# Remove old alternatives if they exist
sudo update-alternatives --remove-all java 2>/dev/null || true
sudo update-alternatives --remove-all javac 2>/dev/null || true

# Set up alternatives
echo "Setting up alternatives..."
sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100
sudo update-alternatives --install /usr/bin/javac javac /opt/jdk8/bin/javac 100
sudo update-alternatives --install /usr/bin/jar jar /opt/jdk8/bin/jar 100
sudo update-alternatives --install /usr/bin/javadoc javadoc /opt/jdk8/bin/javadoc 100

# Set JDK 8 as default
sudo update-alternatives --set java /opt/jdk8/bin/java
sudo update-alternatives --set javac /opt/jdk8/bin/javac

# Set JAVA_HOME
echo "export JAVA_HOME=/opt/jdk8" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

# Clean up
rm /tmp/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz

# Source and verify
source ~/.bashrc

echo ""
echo "Verifying installation..."
java -version
javac -version

echo ""
echo "JAVA_HOME is set to: $JAVA_HOME"
echo "JDK 8 installation complete!"

java -version
sleep 10
export LC_ALL=C
export LANG=C
export LANGUAGE=C
export TARGET_SCREEN_WIDTH=720
export TARGET_SCREEN_HEIGHT=1280
export TW_THEME=portrait_hdpi


# Find and patch BoardConfig.mk
BOARD_CONFIG=$(find device/ -name "BoardConfig.mk" -path "*/samsung/*" | head -1)
if [[ -f "$BOARD_CONFIG" ]]; then
    sed -i '/TARGET_SCREEN_WIDTH/d' "$BOARD_CONFIG"
    sed -i '/TARGET_SCREEN_HEIGHT/d' "$BOARD_CONFIG"  
    sed -i '/TW_THEME/d' "$BOARD_CONFIG"
    echo "TARGET_SCREEN_WIDTH := 720" >> "$BOARD_CONFIG"
    echo "TARGET_SCREEN_HEIGHT := 1280" >> "$BOARD_CONFIG"
    echo "T

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


