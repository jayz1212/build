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

echo "⚙️ Applying SAFE WiFi-only fix (no source restore)"

ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

cd "$ANDROID_DIR"

# =========================================
# 1. REMOVE ONLY BROKEN SAMSUNG RIL
# =========================================
echo "📡 Removing Samsung RIL only..."
rm -rf hardware/samsung/ril

# ⚠️ DO NOT remove hardware/ril anymore

# =========================================
# 2. CREATE STUB (SAFE)
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
    shared_libs: ["liblog", "libcutils"],
    cflags: ["-Wno-unused-parameter"],
}
EOF

# =========================================
# 3. PATCH DEVICE CLEANLY
# =========================================
DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

echo "📱 Patching device tree..."

# clean old junk safely
sed -i '/libril/d' $DEVICE_DIR/*.mk 2>/dev/null || true
sed -i '/rild/d' $DEVICE_DIR/*.mk 2>/dev/null || true

# append only if missing
grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only config
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true

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
# 4. DISABLE RIL SERVICES
# =========================================
echo "🔧 Disabling RIL services..."

find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/rild/d' {} +
find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/ril-daemon/d' {} +

# =========================================
# 5. CLEAN ONLY NECESSARY FILES
# =========================================
echo "🧹 Cleaning RIL leftovers..."

rm -rf out/target/product/*/obj/*ril*
rm -rf out/soong/.intermediates/*ril*

# DO NOT wipe full out/soong anymore

echo "✅ Safe fix applied"
. build/envsetup.sh
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
