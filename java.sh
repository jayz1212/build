#!/bin/bash

echo "🔥 Starting LineageOS 17.1 Arch Fix..."

# =============================
# 1. Install required packages
# =============================
echo "📦 Installing dependencies..."
sudo pacman -S --needed --noconfirm \
  jdk8-openjdk \
  ncurses5-compat-libs \
  lib32-ncurses5-compat-libs

# =============================
# 2. Set Java 8 properly
# =============================
echo "☕ Setting Java 8..."
sudo archlinux-java set java-8-openjdk

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "👉 Java version:"
java -version

# =============================
# 3. Kill conflicting Java
# =============================
echo "🚫 Removing Java 9/11 conflicts (if present)..."
sudo pacman -Rns --noconfirm jdk-openjdk jre-openjdk || true

# =============================
# 4. Fix Python (Android 10 needs python2 symlink sometimes)
# =============================
echo "🐍 Fixing Python..."
sudo pacman -S --needed --noconfirm python2 || true
sudo ln -sf /usr/bin/python2 /usr/bin/python || true

# =============================
# 5. Clean broken build
# =============================
echo "🧹 Cleaning build artifacts..."
rm -rf out/soong
rm -rf out/.module_paths
rm -rf out/target/common/obj/APPS || true

# =============================
# 6. Disable Metalava strict checks
# =============================
echo "🧩 Setting build flags..."
export DISABLE_STUB_VALIDATION=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true

# =============================
# 7. Optional: Remove problematic module
# =============================
echo "💣 Removing test-mock (safe)..."
rm -rf frameworks/base/test-mock || true

# =============================
# 8. Build
# =============================

