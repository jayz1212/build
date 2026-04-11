#!/bin/bash
# fix_twrp_build_final.sh

cd /tmp/src/android

echo "========================================="
echo "Final TWRP Build Fix"
echo "========================================="

# 1. Remove the broken Python 2.7 source install (if any)
echo "Cleaning up broken Python installation..."
sudo rm -rf /usr/local/bin/python2*
sudo rm -rf /usr/local/lib/python2*
sudo rm -rf /tmp/Python-2.7.18

# 2. Install Python 2 from Debian 11 (binary, no compilation)
echo "Installing Python 2 from Debian 11..."
sudo bash -c 'cat > /etc/apt/sources.list.d/bullseye.list << EOF
deb [trusted=yes] http://deb.debian.org/debian bullseye main
EOF'

sudo apt update
sudo apt install -y python2 python2-minimal
sudo rm /etc/apt/sources.list.d/bullseye.list
sudo apt update

# 3. Set up Python alternatives
echo "Setting up Python alternatives..."
sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 2
sudo update-alternatives --set python /usr/bin/python2

# 4. Create python2 symlink if needed
sudo ln -sf /usr/bin/python2 /usr/local/bin/python2

# 5. Fix the build script
echo "Fixing check_radio_versions.py..."
if [ -f "build/tools/check_radio_versions.py" ]; then
    cp build/tools/check_radio_versions.py build/tools/check_radio_versions.py.bak
    sed -i 's/print "\([^"]*\)"/print("\1")/g' build/tools/check_radio_versions.py
    sed -i "s/print '\([^']*\)'/print('\1')/g" build/tools/check_radio_versions.py
fi

# 6. Fix screen resolution for A5000
echo "Setting screen resolution..."
BOARD_CONFIG=$(find device/ -name "BoardConfig.mk" 2>/dev/null | grep -E "a5|a5000" | head -1)

if [ -n "$BOARD_CONFIG" ]; then
    echo "Found: $BOARD_CONFIG"
    sed -i '/TARGET_SCREEN_WIDTH/d' "$BOARD_CONFIG"
    sed -i '/TARGET_SCREEN_HEIGHT/d' "$BOARD_CONFIG"
    sed -i '/TW_THEME/d' "$BOARD_CONFIG"
    cat >> "$BOARD_CONFIG" << EOF

# Samsung A5000 configuration
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TW_THEME := portrait_hdpi
EOF
else
    echo "BoardConfig.mk not found, setting environment variables instead"
    export TARGET_SCREEN_WIDTH=720
    export TARGET_SCREEN_HEIGHT=1280
    export TW_THEME=portrait_hdpi
fi

# 7. Set up Java 8
if ! java -version 2>&1 | grep -q 'version "1.8\|version "8'; then
    echo "Installing Java 8..."
    cd /tmp
    wget -q https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
    sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/
    sudo mv /opt/jdk8u432-b06 /opt/jdk8
    sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100
    sudo update-alternatives --set java /opt/jdk8/bin/java
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
fi

# 8. Verify setup
echo ""
echo "========================================="
echo "Environment Verification"
echo "========================================="
echo "Python version: $(python --version 2>&1)"
echo "Python path: $(which python)"
echo "Java version: $(java -version 2>&1 | head -1)"
echo "JAVA_HOME: ${JAVA_HOME:-/opt/jdk8}"

# 9. Build
echo ""
echo "========================================="
echo "Starting Build"
echo "========================================="

export JAVA_HOME=/opt/jdk8
export PATH=$JAVA_HOME/bin:$PATH
export TARGET_SCREEN_WIDTH=720
export TARGET_SCREEN_HEIGHT=1280
export TW_THEME=portrait_hdpi

# Source build environment
if [ -f "build/envsetup.sh" ]; then
    source build/envsetup.sh
    lunch omni_a5ltechn-eng
    make recoveryimage
else
    echo "ERROR: build/envsetup.sh not found!"
    echo "Are you in the Android source root directory?"
    exit 1
fi
