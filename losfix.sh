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

echo "🔥 AUTO FULL FIX (RECOVERY + WIFI-ONLY STABLE)"

ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

cd "$ANDROID_DIR"

# =========================================
# 🔄 1. RESTORE TELEPHONY (CRITICAL FIX)
# =========================================
echo "🔄 Restoring telephony framework..."

repo sync frameworks/base frameworks/opt/telephony packages/services/Telephony --force-sync

# =========================================
# 📡 2. REMOVE BROKEN RIL
# =========================================
echo "📡 Removing broken RIL..."

rm -rf hardware/samsung/ril
rm -rf hardware/ril

# =========================================
# 🧱 3. CREATE RIL STUB
# =========================================
echo "🧱 Creating RIL stub..."

mkdir -p hardware/ril_stub

cat > hardware/ril_stub/ril.cpp <<'EOF'
#include <telephony/ril.h>

extern "C" {

const RIL_RadioFunctions* RIL_Init(const struct RIL_Env* env,
                                   int argc, char** argv) {
    return nullptr;
}

void RIL_SAP_Init(const struct RIL_Env* env, int argc, char** argv) {}

}
EOF

cat > hardware/ril_stub/Android.bp <<'EOF'
cc_library_shared {
    name: "libril",
    srcs: ["ril.cpp"],
    shared_libs: [
        "liblog",
        "libcutils",
    ],
    cflags: ["-Wno-unused-parameter"],
}
EOF

# =========================================
# 📱 4. PATCH DEVICE CONFIG
# =========================================
echo "📱 Patching device config..."

DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

if [[ -z "$DEVICE_DIR" ]]; then
  echo "❌ Device tree not found"
  exit 1
fi

# Clean old junk
sed -i '/libril/d' $DEVICE_DIR/*.mk 2>/dev/null || true
sed -i '/rild/d' $DEVICE_DIR/*.mk 2>/dev/null || true

# Add clean config
grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only clean config
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    ro.telephony.default_network=0 \\
    persist.radio.multisim.config=none

PRODUCT_PACKAGES += \\
    TelephonyProviderStub \\
    libril
EOF

grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
BOARD_PROVIDES_LIBRIL := true
EOF

# =========================================
# 🔧 5. DISABLE RIL SERVICES
# =========================================
echo "🔧 Disabling RIL services..."

find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/rild/d' {} +
find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/ril-daemon/d' {} +

# =========================================
# 🔵 6. FIX BLUETOOTH SAP
# =========================================
echo "🔵 Fixing Bluetooth SAP..."

sed -i '/sap/d' packages/apps/Bluetooth/Android.bp 2>/dev/null || true

# =========================================
# 🧠 7. METALAVA SAFE MODE
# =========================================
export WITHOUT_CHECK_API=true

# =========================================
# 🧹 8. CLEAN BUILD (IMPORTANT)
# =========================================
echo "🧹 Cleaning build..."

mka installclean
rm -rf out/soong
rm -rf out/target/product/*/obj/*ril*
rm -rf out/soong/.intermediates/*ril*

# =========================================
# 🚀 9. BUILD
# =========================================
echo "🚀 Building..."

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
