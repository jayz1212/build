#!/bin/bash

set -e

echo "🔥 LineageOS 17.1 Ultimate Arch Fix + Build"

# =============================
# 1. Install required packages
# =============================
echo "📦 Installing base dependencies..."
sudo pacman -S --needed --noconfirm \
  jdk8-openjdk \
  ncurses \
  python \
  git \
  base-devel

# =============================
# 2. Fix Java (CRITICAL)
# =============================
echo "☕ Setting Java 8..."

sudo archlinux-java set java-8-openjdk || true

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "👉 Java check:"
java -version

# HARD FAIL if not Java 8
if ! java -version 2>&1 | grep -q "1.8"; then
  echo "❌ ERROR: Java 8 not active. Fix this first."
  exit 1
fi

# =============================
# 3. Fix ncurses compatibility
# =============================
echo "🔧 Fixing ncurses compatibility..."
sudo ln -sf /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5 || true
sudo ln -sf /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5 || true

# =============================
# 4. Fix Python symlink
# =============================
echo "🐍 Fixing python symlink..."
sudo ln -sf /usr/bin/python3 /usr/bin/python || true

# =============================
# 5. Clean previous broken builds
# =============================
echo "🧹 Cleaning old build artifacts..."
rm -rf out/soong out/.module_paths || true

# =============================
# 6. Setup build environment
# =============================
echo "⚙️ Setting up build env..."
source build/envsetup.sh

# AUTO detect device if possible
if [ -z "$1" ]; then
  echo "❗ Usage: ./build_los17.sh <device>"
  echo "Example: ./build_los17.sh blossom"
  exit 1
fi

DEVICE=$1

echo "📱 Lunching device: lineage_${DEVICE}-userdebug"
lunch lineage_${DEVICE}-userdebug

# =============================
# 7. Build flags (Metalava fix)
# =============================
echo "🧩 Applying compatibility flags..."
export DISABLE_STUB_VALIDATION=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true

# =============================
# 8. Pre-emptive fix (common crash)
# =============================
echo "💣 Removing problematic test-mock module..."
rm -rf frameworks/base/test-mock || true

# =============================
# 9. Start build
# =============================
echo "🚀 Building..."
mka bacon -j$(nproc)

echo "✅ BUILD FINISHED!"
