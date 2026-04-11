#!/bin/bash
# build_twrp_complete.sh

set -e

cd /tmp/src/android

echo "========================================="
echo "Setting up build environment for TWRP"
echo "========================================="

# 1. Install Python 2 from Debian 11 (binary)
install_python2() {
    if command -v python2 &> /dev/null; then
        echo "✅ Python 2 already present"
        return 0
    fi
    
    echo "Installing Python 2 from Debian 11..."
    echo "deb [trusted=yes] http://deb.debian.org/debian bullseye main" | sudo tee /etc/apt/sources.list.d/bullseye.list
    sudo apt update
    sudo apt install -y python2 python2-minimal
    sudo rm /etc/apt/sources.list.d/bullseye.list
    sudo apt update
    
    # Create symlink
    sudo ln -sf /usr/bin/python2 /usr/local/bin/python
    
    echo "✅ Python 2 installed"
}

# 2. Set up Java 8
setup_java8() {
    if java -version 2>&1 | grep -q 'version "1.8\|version "8'; then
        echo "✅ Java 8 already present"
        return 0
    fi
    
    echo "Setting up Java 8..."
    cd /tmp
    wget -q https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
    sudo tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/
    sudo mv /opt/jdk8u432-b06 /opt/jdk8
    sudo update-alternatives --install /usr/bin/java java /opt/jdk8/bin/java 100
    sudo update-alternatives --set java /opt/jdk8/bin/java
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
    
    export JAVA_HOME=/opt/jdk8
    export PATH=$JAVA_HOME/bin:$PATH
    echo "✅ Java 8 installed"
}

# 3. Fix Python script in build tree
fix_build_scripts() {
    echo "Fixing Python 2/3 compatibility..."
    
    if [ -f "build/tools/check_radio_versions.py" ]; then
        # Convert to Python 3 compatible
        sed -i 's/print "\([^"]*\)"/print("\1")/g' build/tools/check_radio_versions.py
        sed -i "s/print '\([^']*\)'/print('\1')/g" build/tools/check_radio_versions.py
    fi
}

# 4. Fix screen resolution for A5000
fix_screen_config() {
    echo "Setting up screen configuration for Samsung A5000..."
    
    # Find BoardConfig.mk
    BOARD_CONFIG=$(find device/ -name "BoardConfig.mk" -path "*/a5ltechn/*" 2>/dev/null | head -1)
    
    if [ -n "$BOARD_CONFIG" ]; then
        # Remove old entries
        sed -i '/TARGET_SCREEN_WIDTH/d' "$BOARD_CONFIG"
        sed -i '/TARGET_SCREEN_HEIGHT/d' "$BOARD_CONFIG"
        sed -i '/TW_THEME/d' "$BOARD_CONFIG"
        
        # Add correct config
        cat >> "$BOARD_CONFIG" << EOF

# Samsung A5000 display configuration
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TW_THEME := portrait_hdpi
EOF
        echo "✅ Screen config added to $BOARD_CONFIG"
    else
        echo "⚠️  BoardConfig.mk not found, skipping"
    fi
}

# 5. Main build
build_twrp() {
    echo ""
    echo "========================================="
    echo "Starting TWRP build"
    echo "========================================="
    
    # Set environment
    export JAVA_HOME=/opt/jdk8
    export PATH=$JAVA_HOME/bin:/usr/local/bin:$PATH
    export TARGET_SCREEN_WIDTH=720
    export TARGET_SCREEN_HEIGHT=1280
    export TW_THEME=portrait_hdpi
    
    # Use Python 2
    alias python=python2
    
    echo "Using:"
    echo "  Java: $(java -version 2>&1 | head -1)"
    echo "  Python: $(python2 --version 2>&1)"
    
    # Build
    source build/envsetup.sh
    lunch omni_a5ltechn-eng
    make recoveryimage
}

# Run all steps
install_python2
setup_java8
fix_build_scripts
fix_screen_config
build_twrp
