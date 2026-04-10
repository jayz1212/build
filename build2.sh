#!/usr/bin/env bash

##set -e

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
    repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b $TWRP_BRANCH --depth=1
fi

# ===== SYNC =====
echo "🔄 Syncing source..."
repo sync -c -j64 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

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

#!/usr/bin/env bash

set -e

DEVICE_PATH="device/samsung/a5ltechn"
BOARD_CONFIG="$DEVICE_PATH/BoardConfig.mk"
FSTAB="$DEVICE_PATH/recovery.fstab"

echo "======================================="
echo " MSM8916 TWRP Auto Patch Script"
echo "======================================="
echo

# ===== Helper function =====
add_or_replace() {
    local KEY="$1"
    local VALUE="$2"

    if grep -q "^$KEY" "$BOARD_CONFIG"; then
        sed -i "s|^$KEY.*|$KEY := $VALUE|" "$BOARD_CONFIG"
        echo "🔁 Updated: $KEY"
    else
        echo "$KEY := $VALUE" >> "$BOARD_CONFIG"
        echo "➕ Added: $KEY"
    fi
}

echo "📦 Patching BoardConfig.mk..."

# ===== Core TWRP flags =====
add_or_replace TW_THEME portrait_hdpi
add_or_replace RECOVERY_VARIANT twrp
add_or_replace TW_EXTRA_LANGUAGES true
add_or_replace TW_SCREEN_BLANK_ON_BOOT true

# ===== Display fix =====
add_or_replace TARGET_RECOVERY_PIXEL_FORMAT RGBX_8888

# ===== Crypto (Android 10 / TWRP 11) =====
add_or_replace TW_INCLUDE_CRYPTO true
add_or_replace TW_INCLUDE_FBE true
add_or_replace TW_USE_FSCRYPT_POLICY 1

# ===== Storage / mounting =====
add_or_replace TW_HAS_MTP true
add_or_replace TW_EXCLUDE_DEFAULT_USB_INIT true

# ===== SELinux permissive (boot fix) =====
if grep -q "BOARD_KERNEL_CMDLINE" "$BOARD_CONFIG"; then
    if ! grep -q "androidboot.selinux=permissive" "$BOARD_CONFIG"; then
        sed -i 's|BOARD_KERNEL_CMDLINE *= *"|&androidboot.selinux=permissive |' "$BOARD_CONFIG"
        echo "➕ Added SELinux permissive to cmdline"
    fi
else
    echo 'BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive' >> "$BOARD_CONFIG"
    echo "➕ Created BOARD_KERNEL_CMDLINE with permissive"
fi

echo

# ===== fstab sanity fix =====
echo "📂 Checking recovery.fstab..."

if [ -f "$FSTAB" ]; then
    sed -i 's|/data[[:space:]]\+ext4|/data ext4 flags=encryptable=footer|' "$FSTAB" || true
    echo "✔ fstab basic crypto patch applied"
else
    echo "⚠️ recovery.fstab not found (skipped)"
fi

echo

# ===== Permissions fix =====
chmod -R u+rw "$DEVICE_PATH"

echo
echo "======================================="
echo "✅ MSM8916 TWRP PATCH COMPLETE"
echo "======================================="
echo
echo "Now run:"
echo "source build/envsetup.sh"
echo "lunch omni_a5ltechn-eng"
echo "mka recoveryimage"
echo


echo "🔧 Applying advanced MSM8916 fixes..."

# Disable VTS garbage
find hardware interfaces vendor -name "*.bp" -exec sed -i \
'/vts/d' {} + 2>/dev/null || true

# Allow missing deps
grep -q ALLOW_MISSING_DEPENDENCIES $BOARD_CONFIG || \
echo "ALLOW_MISSING_DEPENDENCIES := true" >> $BOARD_CONFIG

grep -q BUILD_BROKEN_VINTF_PRODUCT_COPY_FILES $BOARD_CONFIG || \
echo "BUILD_BROKEN_VINTF_PRODUCT_COPY_FILES := true" >> $BOARD_CONFIG

# Fix missing splash
mkdir -p bootable/recovery/gui/theme/common
echo '<?xml version="1.0"?><splash></splash>' > bootable/recovery/gui/theme/common/splash.xml

echo "✅ Advanced fixes applied"




# ===== BUILD =====
echo "🛠️ Building TWRP..."
mka recoveryimage -j$JOBS 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

# ===== DONE =====
echo
echo "======================================="
echo "✅ BUILD COMPLETE!"
echo "📍 Output:"
echo "out/target/product/${DEVICE}/recovery.img"
echo "======================================="
# ===== LUNCH =====
echo "🍱 Lunching device..."
lunch lineage_${DEVICE}-eng

