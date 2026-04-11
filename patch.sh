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
