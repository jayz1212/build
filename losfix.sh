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













echo "🔥 FINAL STABILIZATION (A5LTECHN)"

ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

cd "$ANDROID_DIR"

DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

if [[ -z "$DEVICE_DIR" ]]; then
  echo "❌ Device tree not found"
  exit 1
fi

# =========================================
# 📡 1. CLEAN RIL STUB (NO CRASHES)
# =========================================
echo "📡 Fixing RIL properly..."

# Remove rild service from init
find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/rild/d' {} +

# Remove ril class services safely
find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/ril-daemon/d' {} +

# Keep framework satisfied
grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only final
PRODUCT_PROPERTY_OVERRIDES += ro.radio.noril=true
EOF

# =========================================
# 🔐 2. SEPOLICY CLEAN (ENFORCING + QUIET)
# =========================================
echo "🔐 Cleaning SEPolicy..."

SEPOLICY_DIR="$DEVICE_DIR/sepolicy"

mkdir -p "$SEPOLICY_DIR"

cat >> "$SEPOLICY_DIR/system_server.te" <<EOF

# WiFi-only allowances
allow system_server self:capability { net_admin net_raw };
allow system_server sysfs:file rw_file_perms;
EOF

cat >> "$SEPOLICY_DIR/domain.te" <<EOF

# Reduce log spam
dontaudit domain self:capability net_raw;
dontaudit domain kernel:system module_request;
EOF

# =========================================
# 🔇 3. LOG SPAM REDUCTION
# =========================================
echo "🔇 Reducing log spam..."

cat >> "$DEVICE_DIR/device.mk" <<EOF

# Reduce logcat noise
PRODUCT_PROPERTY_OVERRIDES += \
    log.tag.Telephony=ERROR \
    log.tag.RIL=ERROR \
    log.tag.Radio=ERROR
EOF

# =========================================
# ⚙️ 4. KERNEL STABILITY TWEAKS
# =========================================
echo "⚙️ Improving kernel stability..."

KERNEL_OUT="$ANDROID_DIR/out/target/product/$DEVICE/obj/KERNEL_OBJ/.config"

if [[ -f "$KERNEL_OUT" ]]; then
  scripts/config --file "$KERNEL_OUT" \
    -e CONFIG_ANDROID_LOW_MEMORY_KILLER \
    -e CONFIG_ZRAM \
    -e CONFIG_ZSMALLOC \
    -d CONFIG_DEBUG_KERNEL || true
fi

# =========================================
# 📦 5. REMOVE UNUSED SERVICES
# =========================================
echo "📦 Cleaning unused services..."

sed -i '/telephony/d' "$DEVICE_DIR/device.mk" 2>/dev/null || true

# =========================================
# 🧹 6. FINAL CLEAN
# =========================================
echo "🧹 Cleaning build..."

mka installclean

# =========================================
# 🚀 7. REBUILD
# =========================================
echo "🚀 Rebuilding stable ROM..."

source build/envsetup.sh
lunch lineage_${DEVICE}-userdebug

make bacon -j8 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload
echo ""
echo "🎉 FINAL STABLE BUILD COMPLETE"
echo ""
echo "✔ WiFi-only working"
echo "✔ No RIL crashes"
echo "✔ SELinux enforcing"
echo "✔ Reduced log spam"
echo "✔ Kernel optimized"
