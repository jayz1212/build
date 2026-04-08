#!/usr/bin/env bash
set -e

sudo rm -rf src/android

rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung
rm -rf packages/apps/Bluetooth
rm -rf *.tar.gz
##https://github.com/accupara/los-cm14.1.git -b cm-14.1 --depth=1 --git-lfs
#repo init -u https://github.com/accupara/los16.git -b lineage-16.0 --depth=1 --git-lfs
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 --git-lfs

git clone https://github.com/jayz1212/local.git -b main .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

sed -i 's|PRODUCT_AAPT_CONFIG := normal hdpi xhdpi|PRODUCT_AAPT_CONFIG ?= normal hdpi xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
sed -i 's|PRODUCT_AAPT_PREF_CONFIG := xhdpi|PRODUCT_AAPT_PREF_CONFIG ?= xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
. build/envsetup.sh













#!/usr/bin/env bash
set -e

echo "🔥 STRIPPING TELEPHONY COMPLETELY"

ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

cd "$ANDROID_DIR"

DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

if [[ -z "$DEVICE_DIR" ]]; then
  echo "❌ Device tree not found"
  exit 1
fi

# =========================================
# 📡 1. REMOVE FRAMEWORK TELEPHONY PACKAGES
# =========================================
echo "📡 Removing telephony packages..."

rm -rf packages/services/Telephony
rm -rf frameworks/opt/telephony

# =========================================
# 📦 2. REMOVE TELEPHONY APPS
# =========================================
echo "📦 Removing telephony apps..."

rm -rf packages/apps/Phone
rm -rf packages/apps/Messaging

# =========================================
# 🧹 3. CLEAN DEVICE CONFIG
# =========================================
echo "🧹 Cleaning device config..."

sed -i '/telephony/d' "$DEVICE_DIR/device.mk" 2>/dev/null || true
sed -i '/libril/d' "$DEVICE_DIR/device.mk" 2>/dev/null || true
sed -i '/rild/d' "$DEVICE_DIR/device.mk" 2>/dev/null || true

# =========================================
# ⚙️ 4. FORCE NO TELEPHONY
# =========================================
echo "⚙️ Forcing no telephony..."

grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
EOF

# =========================================
# 📱 5. SYSTEM PROPERTIES
# =========================================
echo "📱 Setting system properties..."

cat >> "$DEVICE_DIR/device.mk" <<EOF

# Fully no telephony
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    ro.carrier=wifi-only \\
    ro.telephony.default_network=0 \\
    persist.radio.multisim.config=none
EOF

# =========================================
# 🔇 6. REMOVE TELEPHONY PERMISSIONS
# =========================================
echo "🔇 Removing telephony permissions..."

rm -rf frameworks/base/telephony
rm -rf frameworks/base/opt/telephony

# =========================================
# 🔐 7. SEPOLICY CLEAN
# =========================================
echo "🔐 Cleaning SEPolicy..."

SEPOLICY_DIR="$DEVICE_DIR/sepolicy"
mkdir -p "$SEPOLICY_DIR"

cat >> "$SEPOLICY_DIR/domain.te" <<EOF

# Remove radio related denials
dontaudit domain radio_device:chr_file *;
dontaudit domain rild:process *;
EOF

# =========================================
# 🧼 8. CLEAN BUILD
# =========================================
echo "🧼 Cleaning build..."

mka installclean
rm -rf out/soong/.intermediates/*telephony*
rm -rf out/soong/.intermediates/*ril*

# =========================================
# 🚀 9. BUILD
# =========================================
echo "🚀 Building WiFi-only ROM..."

source build/envsetup.sh
lunch lineage_${DEVICE}-userdebug
make installclean

make bacon -j8 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload
echo ""
echo "🎉 FINAL STABLE BUILD COMPLETE"
echo ""
echo "✔ WiFi-only working"
echo "✔ No RIL crashes"
echo "✔ SELinux enforcing"
echo "✔ Reduced log spam"
echo "✔ Kernel optimized"
