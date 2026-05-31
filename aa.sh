#!/bin/bash

# ==========================================
# Android ROM ZIP Build Checker
# For old-style new.dat ROM packages
# ==========================================

ZIP="$1"

if [ -z "$ZIP" ]; then
    echo "Usage: $0 rom.zip"
    exit 1
fi

if [ ! -f "$ZIP" ]; then
    echo "File not found: $ZIP"
    exit 1
fi

WORKDIR="romcheck_$(date +%s)"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

echo "[1/6] Extracting required files..."
unzip -j "../$ZIP" \
system.new.dat \
system.transfer.list \
vendor.new.dat \
vendor.transfer.list \
META-INF/com/android/metadata \
META-INF/com/google/android/updater-script \
>/dev/null 2>&1

echo "[2/6] Checking ZIP metadata..."
echo "--------------------------------"
cat metadata 2>/dev/null || true
echo
echo "--------------------------------"

# Check if sdat2img exists
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found."
    exit 1
fi

if [ ! -f ../sdat2img.py ] && [ ! -f ./sdat2img.py ]; then
    echo "Missing sdat2img.py"
    echo "Download it first."
    exit 1
fi

SDAT="../sdat2img.py"
[ -f ./sdat2img.py ] && SDAT="./sdat2img.py"

echo "[3/6] Converting system.new.dat to system.img..."
python3 "$SDAT" system.transfer.list system.new.dat system.img

if [ ! -f system.img ]; then
    echo "Failed creating system.img"
    exit 1
fi

mkdir -p sys

echo "[4/6] Mounting system.img..."
sudo mount -o loop system.img sys || exit 1

echo "[5/6] Reading build.prop..."
echo "--------------------------------"

grep -E "ro.build.type|ro.secure|ro.adb.secure|ro.debuggable|ro.product.device|ro.build.fingerprint" \
sys/system/build.prop 2>/dev/null

echo "--------------------------------"

echo "[6/6] Cleaning up..."
sudo umount sys
cd ..
rm -rf "$WORKDIR"

echo "Done."
