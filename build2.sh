#!/usr/bin/env bash

set -e

# ===== CONFIG =====
TWRP_BRANCH="twrp-10.0"
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
    repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b $TWRP_BRANCH
fi

# ===== SYNC =====
echo "🔄 Syncing source..."
repo sync -j$JOBS --force-sync

# ===== CLONE DEVICE TREES =====
echo "📦 Cloning device trees..."

git clone -b lineage-17.1 https://github.com/LightningFastDevices/android_device_samsung_a5ltechn device/samsung/a5ltechn
git clone -b lineage-17.1 https://github.com/LightningFastDevices/android_device_samsung_a5-common device/samsung/a5-common
git clone -b lineage-17.1 https://github.com/LightningFastDevices/android_device_samsung_msm8916-common device/samsung/msm8916-common
git clone -b lineage-17.1 https://github.com/enrico-mo/android_device_samsung_qcom-common device/samsung/qcom-common

git clone -b lineage-17.1 https://github.com/LightningFastDevices/proprietary_vendor_samsung vendor/samsung

git clone -b lineage-17.1 https://github.com/Galaxy-MSM8916/android_kernel_samsung_msm8916 kernel/samsung/msm8916

git clone -b lineage-17.1 https://github.com/LineageOS/android_hardware_samsung hardware/samsung

echo "✅ Cloning done!"
echo

# ===== BUILD ENV =====
echo "⚙️ Setting up build environment..."
source build/envsetup.sh

# ===== LUNCH =====
echo "🍱 Lunching device..."
lunch omni_${DEVICE}-eng

# ===== BUILD =====
echo "🛠️ Building TWRP..."
mka recoveryimage -j$JOBS

# ===== DONE =====
echo
echo "======================================="
echo "✅ BUILD COMPLETE!"
echo "📍 Output:"
echo "out/target/product/${DEVICE}/recovery.img"
echo "======================================="
