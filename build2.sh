#!/usr/bin/env bash
rm -rf device/samsung
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


git clone --depth=1 https://github.com/Galaxy-MSM8916/android_device_samsung_a5ltechn -b lineage-17.1 device/samsung/a5ltechn
git clone https://github.com/Galaxy-MSM8916/android_device_samsung_a5-common -b lineage-16.0 device/samsung/a5-common
git clone --depth=1 https://github.com/Galaxy-MSM8916/android_device_samsung_msm8916-common -b lineage-17.1 device/samsung/msm8916-common
git clone --depth=1 https://github.com/LineageOS/android_device_samsung_qcom-common -b lineage-17.1 device/samsung/qcom-common
echo "✅ Cloning done!"
echo
sed -i 's|vendor/omni/config/common.mk|vendor/twrp/config/common.mk|g' device/samsung/a5-common/*.mk
sed -i 's|$(call inherit-product, vendor/omni/config/gsm.mk)||g' device/samsung/a5-common/*.mk

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


#!/usr/bin/env bash

set -e

DEVICE="a5ltechn"
DEVICE_PATH="device/samsung/$DEVICE"
BOARD_CONFIG="$DEVICE_PATH/BoardConfig.mk"
FSTAB="$DEVICE_PATH/recovery.fstab"

echo "======================================="
echo " MSM8916 TWRP FULL AUTO PATCH"
echo "======================================="
echo

# ===== Helper =====
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

# ===== Core TWRP =====
add_or_replace TW_THEME portrait_hdpi
add_or_replace RECOVERY_VARIANT twrp
add_or_replace TW_EXTRA_LANGUAGES true
add_or_replace TW_SCREEN_BLANK_ON_BOOT true

# ===== Display fix =====
add_or_replace TARGET_RECOVERY_PIXEL_FORMAT RGBX_8888

# ===== Crypto =====
add_or_replace TW_INCLUDE_CRYPTO true
add_or_replace TW_INCLUDE_FBE true
add_or_replace TW_USE_FSCRYPT_POLICY 1

# ===== Storage =====
add_or_replace TW_HAS_MTP true
add_or_replace TW_EXCLUDE_DEFAULT_USB_INIT true

# ===== Build fixes =====
add_or_replace ALLOW_MISSING_DEPENDENCIES true
add_or_replace BUILD_BROKEN_VINTF_PRODUCT_COPY_FILES true

# ===== SELinux permissive =====
if grep -q "BOARD_KERNEL_CMDLINE" "$BOARD_CONFIG"; then
    if ! grep -q "androidboot.selinux=permissive" "$BOARD_CONFIG"; then
        sed -i 's|BOARD_KERNEL_CMDLINE *= *"|&androidboot.selinux=permissive |' "$BOARD_CONFIG"
        echo "➕ Added SELinux permissive"
    fi
else
    echo 'BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive' >> "$BOARD_CONFIG"
    echo "➕ Created BOARD_KERNEL_CMDLINE"
fi

echo

# ===== Fix missing splash.xml =====
echo "🎨 Fixing missing splash.xml..."

mkdir -p bootable/recovery/gui/theme/common

cat > bootable/recovery/gui/theme/common/splash.xml <<EOF
<?xml version="1.0"?>
<splash>
    <image resource="splash" />
</splash>
EOF

echo "✔ splash.xml created"

echo

# ===== REMOVE VTS / TEST / FUZZER =====
echo "🧹 Removing VTS / test modules..."

find hardware/interfaces -type d \( -name "vts" -o -name "tests" -o -name "fuzzer" \) -exec rm -rf {} + 2>/dev/null || true
find vendor -type d \( -name "vts" -o -name "tests" -o -name "fuzzer" \) -exec rm -rf {} + 2>/dev/null || true

echo "✔ VTS removed"

echo

# ===== Optional fstab patch =====
echo "📂 Checking recovery.fstab..."

if [ -f "$FSTAB" ]; then
    sed -i 's|/data[[:space:]]\+ext4|/data ext4 flags=encryptable=footer|' "$FSTAB" || true
    echo "✔ fstab patched"
else
    echo "⚠️ recovery.fstab not found (skipped)"
fi

echo

# ===== Permissions =====
chmod -R u+rw "$DEVICE_PATH"

echo
echo "======================================="
echo "✅ ALL PATCHES APPLIED SUCCESSFULLY"
echo "======================================="
echo
echo "Next:"
echo "export ALLOW_MISSING_DEPENDENCIES=true"
echo "source build/envsetup.sh"
echo "lunch omni_${DEVICE}-eng"
echo "mka recoveryimage"
echo

#git clone --depth=1 https://github.com/omnirom/android_vendor_omni -b android-10 vendor/omni
lunch omni_${DEVICE}-eng
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


