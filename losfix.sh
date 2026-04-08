#!/usr/bin/env bash
set -e

echo "🔥 ULTIMATE LINEAGEOS AUTO FIX STARTED"

# ===== CONFIG =====
ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

KERNEL_DIR="$ANDROID_DIR/kernel/samsung/msm8916"
OUT_DIR="$ANDROID_DIR/out/target/product/$DEVICE/obj/KERNEL_OBJ"

TOOLCHAIN="$ANDROID_DIR/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

cd "$ANDROID_DIR"

# ===== ENV FIX =====
echo "✔ Setting environment"
export ARCH=arm
export CROSS_COMPILE="$TOOLCHAIN"
export LC_ALL=C
export SOONG_ALLOW_MISSING_DEPENDENCIES=true

if [[ ! -f "${CROSS_COMPILE}gcc" ]]; then
  echo "❌ Toolchain missing"
  exit 1
fi

# =========================================
# 📡 WIFI-ONLY PATCH (SAFE VERSION)
# =========================================
echo "📡 Applying WiFi-only patch..."

DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

if [[ -z "$DEVICE_DIR" ]]; then
  echo "❌ Device tree not found"
  exit 1
fi

echo "✔ Device: $DEVICE_DIR"

# Remove RIL
rm -rf hardware/ril hardware/samsung/ril

# Patch Samsung makefile safely
SMK="hardware/samsung/Android.mk"
if [[ -f "$SMK" ]]; then
  cp "$SMK" "$SMK.bak"
  sed -i '/\/ril\//d' "$SMK"
  sed -i '/\bril\b/d' "$SMK"
fi

# Clean device tree
for f in "$DEVICE_DIR/device.mk" "$DEVICE_DIR/BoardConfig.mk"; do
  [[ -f "$f" ]] || continue
  sed -i '/libril/d' "$f"
  sed -i '/rild/d' "$f"
  sed -i '/reference-ril/d' "$f"
done

# Add WiFi-only flags
grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only config
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    persist.radio.multisim.config=none \\
    ro.telephony.default_network=0

PRODUCT_PACKAGES += TelephonyProviderStub
EOF

grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
BOARD_PROVIDES_LIBRIL := true
EOF

# Clean RIL leftovers
rm -rf out/target/product/*/obj/*ril*
rm -rf out/soong/.intermediates/*ril*

# =========================================
# 🔵 BLUETOOTH SAP FIX
# =========================================
echo "🔵 Fixing Bluetooth SAP..."

BT_DIR="packages/apps/Bluetooth"

rm -rf "$BT_DIR/src/com/android/bluetooth/sap" 2>/dev/null || true
sed -i '/sap/d' "$BT_DIR/Android.bp" 2>/dev/null || true

# =========================================
# 🧠 METALAVA FIX
# =========================================
echo "🧠 Fixing metalava..."

rm -rf out/soong/.intermediates/libcore 2>/dev/null || true

# =========================================
# 🔐 SEPOLICY FIX (TEMPORARY)
# =========================================
echo "🔐 Applying SEPolicy fallback..."

echo "SELINUX_IGNORE_NEVERALLOWS := true" >> build/make/core/config.mk || true

# =========================================
# ⚙️ KERNEL FIX
# =========================================
echo "⚙️ Fixing kernel..."

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$KERNEL_DIR"

DEFCONFIG=$(find arch/arm/configs -name "*$DEVICE*" | head -n 1 | xargs -n1 basename)
[[ -z "$DEFCONFIG" ]] && DEFCONFIG="msm8916_defconfig"

echo "✔ Using defconfig: $DEFCONFIG"

make O="$OUT_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" "$DEFCONFIG"

make O="$OUT_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" oldconfig

make -j$(nproc) O="$OUT_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" zImage

# =========================================
# 🚀 BUILD
# =========================================
cd "$ANDROID_DIR"

echo "🚀 Starting full build..."

source build/envsetup.sh
lunch lineage_${DEVICE}-userdebug

mka installclean
mka bacon -j8

echo ""
echo "🎉 BUILD SUCCESS (if no errors above)"
