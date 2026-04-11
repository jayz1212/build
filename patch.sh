#!/bin/bash
# build_twrp_with_python2_check.sh

# Function to check and install Python 2 if needed
setup_python2() {
    if command -v python2 &> /dev/null && python2 --version 2>&1 | grep -q "Python 2"; then
        echo "✅ Python 2 already available"
        export PATH="/usr/local/bin:$PATH"
        return 0
    fi
    
    echo "⚠️  Python 2 not found, installing from source..."
    
    # Install build dependencies
    sudo apt update
    sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    
    # Download and compile Python 2.7
    cd /tmp
    wget -q --show-progress https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
    tar xzf Python-2.7.18.tgz
    cd Python-2.7.18
    ./configure --prefix=/usr/local --enable-optimizations
    make -j$(nproc)
    sudo make altinstall
    sudo ln -sf /usr/local/bin/python2.7 /usr/local/bin/python2
    cd /tmp
    rm -rf Python-2.7.18
    
    echo "✅ Python 2.7 installed"
}

# Main build process
main() {
    cd /tmp/src/android
    
    # Setup Python 2 (only if needed)
    setup_python2
    
    # Set environment to use Python 2
    export PATH="/usr/local/bin:$PATH"
    
    # Verify Python version
    echo "Using Python:"
    python2 --version
    
    # Fix the Python script if needed
    if [ -f "build/tools/check_radio_versions.py" ]; then
        echo "Checking build scripts..."
        # Make a backup
        cp build/tools/check_radio_versions.py build/tools/check_radio_versions.py.bak
        # Fix print statements for Python 3 compatibility if needed
        sed -i 's/print "\([^"]*\)"/print("\1")/g' build/tools/check_radio_versions.py
    fi
    
    # Build TWRP
    source build/envsetup.sh
    lunch omni_a5ltechn-eng
    make recoveryimage
}

# Run the build
main
