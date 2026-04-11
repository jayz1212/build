

#!/usr/bin/env bash

# export PYTHON=python3.10
# export PYTHON=python3
sudo rm -rf src/android

rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung
rm -rf packages/apps/Bluetooth
rm -rf *.tar.gz
##https://github.com/accupara/los-cm14.1.git -b cm-14.1 --depth=1 --git-lfs
#repo init -u https://github.com/accupara/los16.git -b lineage-16.0 --depth=1 --git-lfs
repo init -u https://github.com/LineageOS/android.git -b lineage-16.0 --depth=1 --git-lfs

git clone https://github.com/jayz1212/local.git -b main .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

sed -i 's|PRODUCT_AAPT_CONFIG := normal hdpi xhdpi|PRODUCT_AAPT_CONFIG ?= normal hdpi xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
sed -i 's|PRODUCT_AAPT_PREF_CONFIG := xhdpi|PRODUCT_AAPT_PREF_CONFIG ?= xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
. build/envsetup.sh



#curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/ril.sh | bash


# export ARCH=arm
# export CC=clang
# export LD=ld.lld
# export AR=llvm-ar
# export NM=llvm-nm
# export STRIP=llvm-strip
# export OBJCOPY=llvm-objcopy
# export OBJDUMP=llvm-objdump
# export READELF=llvm-readelf
# export HOSTCC=clang
# export HOSTCXX=clang++
# export CLANG_TRIPLE=arm-linux-gnueabi-
# export PATH_OVERRIDE_SOONG="prebuilts/build-tools/path/linux-x86/path_override"
# export SUBARCH=arm
# export CROSS_COMPILE=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-


# # 1. Force correct Java (VERY IMPORTANT)
# export JAVA_HOME=$(pwd)/prebuilts/jdk/jdk11/linux-x86
# export PATH=$JAVA_HOME/bin:$PATH

# 2. Clean only the broken module
rm -rf out/soong/.intermediates/libcore

# 3. Disable strict metalava checks (safe for msm8916)
export RELAX_USES_LIBRARY_CHECK=true
export BUILD_BROKEN_MISSING_API_CHECKS=true

# 4. Rebuild

# # Disable stack protector
# scripts/config --disable CC_STACKPROTECTOR
# scripts/config --disable CC_STACKPROTECTOR_STRONG
# scripts/config --disable CC_STACKPROTECTOR_REGULAR






# curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/fixlib.sh | bash

wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb && sudo dpkg -i libtinfo5_6.3-2_amd64.deb && rm -f libtinfo5_6.3-2_amd64.deb
wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb && sudo dpkg -i libncurses5_6.3-2_amd64.deb && rm -f libncurses5_6.3-2_amd64.deb

source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/compilerfix.sh)
source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/4ff76f942afb63b356034ad5e4068bb41d7781c8/fixsap.sh)
#source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/java2.sh | bash)
set -e

echo "⚙️ Applying FINAL WiFi-only fix (FULL PATCH)"

ANDROID_DIR="/tmp/src/android"
DEVICE="a5ltechn"

cd "$ANDROID_DIR"

# =========================================
# 1. REMOVE SAMSUNG RIL
# =========================================
echo "📡 Removing Samsung RIL..."
rm -rf hardware/samsung/ril

# =========================================
# 2. PATCH SAMSUNG ANDROID.MK
# =========================================
echo "🔧 Patching hardware/samsung/Android.mk..."

SMK="hardware/samsung/Android.mk"

if [ -f "$SMK" ]; then
  cp "$SMK" "${SMK}.bak"

  sed -i '/hardware\/samsung\/ril/d' "$SMK"
  sed -i '/\/ril\//d' "$SMK"
  sed -i '/\bril\b/d' "$SMK"
fi

# =========================================
# 3. FORCE REMOVE RILD (NUCLEAR FIX)
# =========================================
echo "💥 Force removing rild completely..."

# Delete rild source entirely
rm -rf hardware/ril/rild

# Break any reference in Android.bp
if [ -f hardware/ril/Android.bp ]; then
  sed -i '/rild/d' hardware/ril/Android.bp
fi

# Break any reference in Android.mk
sed -i '/rild/d' hardware/ril/Android.mk 2>/dev/null || true

# Remove from device tree
DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)
sed -i '/rild/d' $DEVICE_DIR/*.mk 2>/dev/null || true

# Remove from init scripts
find $DEVICE_DIR -name "*.rc" -exec sed -i '/rild/d' {} +
find $DEVICE_DIR -name "*.rc" -exec sed -i '/ril-daemon/d' {} +

echo "✅ rild completely removed from build graph"



# =========================================
# 4. FORCE DISABLE reference-ril (REAL FIX)
# =========================================
echo "💥 Force disabling reference-ril..."

# Remove source
rm -rf hardware/ril/reference-ril

# Kill module in Android.bp (important)
if [ -f hardware/ril/Android.bp ]; then
  sed -i 's/name: "reference-ril"/name: "reference-ril_disabled"/g' hardware/ril/Android.bp
  sed -i '/reference-ril/d' hardware/ril/Android.bp
fi

# Kill from Android.mk
sed -i '/reference-ril/d' hardware/ril/Android.mk 2>/dev/null || true

# Kill from ALL device/vendor trees (strong)
grep -rl "reference-ril" device/ vendor/ 2>/dev/null | xargs -r sed -i '/reference-ril/d'

echo "✅ reference-ril fully removed from build graph"
# =========================================
# 4. CREATE RIL STUB
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
# 5. PATCH DEVICE TREE
# =========================================
echo "📱 Patching device tree..."

DEVICE_DIR=$(find device -type d -name "*$DEVICE*" | head -n 1)

# clean old entries
sed -i '/libril/d' $DEVICE_DIR/*.mk 2>/dev/null || true
sed -i '/rild/d' $DEVICE_DIR/*.mk 2>/dev/null || true

# add WiFi-only config
grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only config
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true

PRODUCT_PACKAGES += \\
    TelephonyProviderStub \\
    libril
EOF

# board config
grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
BOARD_PROVIDES_LIBRIL := true
EOF

# =========================================
# 6. DISABLE RIL SERVICES (INIT)
# =========================================
echo "🔧 Disabling RIL services..."

find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/rild/d' {} +
find "$DEVICE_DIR" -name "*.rc" -exec sed -i '/ril-daemon/d' {} +

# =========================================
# 7. CLEAN RIL ARTIFACTS
# =========================================
echo "🧹 Cleaning RIL leftovers..."

rm -rf out/target/product/*/obj/*ril*
rm -rf out/soong/.intermediates/*ril*


echo "✅ FINAL WiFi-only fix applied"
cd /tmp/src/android

. build/envsetup.sh
lunch lineage_a5ltechn-userdebug


# 🔥 HARD FIX
# ln -sf $JDK8/bin/java prebuilts/jdk/jdk9/linux-x86/bin/java

# hash -r

# which java
# java -version

# CLEAN AFTER FIX
# rm -rf out/soong/.intermediates
# rm -rf out/soong/.intermediates/frameworks/base
# rm -rf out/soong/.intermediates/libcore
# rm -rf out/soong/.intermediates/frameworks/base/api*
# build
export _JAVA_OPTIONS="-Xmx2g"




########################################################################################################
#!/usr/bin/env bash
set -e

echo "🔥 Applying FULL kernel/toolchain fix..."

# ===== 1. CLEAN BAD ENV =====
echo "✔ Resetting environment"
unset CROSS_COMPILE

# ===== 2. SET CORRECT TOOLCHAIN =====
TOOLCHAIN="/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

if [ ! -f "${TOOLCHAIN}gcc" ]; then
    echo "❌ Toolchain not found!"
    echo "Expected: ${TOOLCHAIN}gcc"
    exit 1
fi

export CROSS_COMPILE=$TOOLCHAIN
echo "✔ CROSS_COMPILE set to:"
echo "   $CROSS_COMPILE"

# ===== 3. FIX ALL WRONG PREFIXES =====
echo "✔ Replacing androidkernel → androideabi (global fix)"

grep -rl "androidkernel-" device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/androidkernel-/androideabi-/g' "$file"
done

# ===== 4. REMOVE LEADING SPACE BUG =====
echo "✔ Fixing leading space in CROSS_COMPILE"

grep -rl 'CROSS_COMPILE=" ' device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/CROSS_COMPILE=" /CROSS_COMPILE="/g' "$file"
done

grep -rl "CROSS_COMPILE= " device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/CROSS_COMPILE= /CROSS_COMPILE=/g' "$file"
done

# ===== 5. FORCE OVERRIDE IN BOARD CONFIG =====
echo "✔ Forcing correct CROSS_COMPILE in BoardConfig"

BOARD_FILES=$(find device -name "BoardConfig*.mk" 2>/dev/null)

for f in $BOARD_FILES; do
    sed -i '/CROSS_COMPILE/d' "$f"
    echo "CROSS_COMPILE := $TOOLCHAIN" >> "$f"
done

# ===== 6. CLEAN OLD KERNEL BUILD =====
echo "✔ Cleaning old kernel build"

rm -rf out/target/product/*/obj/KERNEL_OBJ

# ===== 7. VERIFY =====
echo "✔ Verifying toolchain..."
if ! command -v ${CROSS_COMPILE}gcc >/dev/null 2>&1; then
    echo "❌ Toolchain not usable!"
    exit 1
fi

echo "🚀 Kernel fix applied successfully!"
########################################################################################################
#!/usr/bin/env bash
set -e

echo "🔑 Fixing pacman keys (non-interactive)..."

sudo rm -rf /etc/pacman.d/gnupg

sudo pacman-key --init
sudo pacman-key --populate archlinux

# Install/update keyring (fallback included)
sudo pacman -Sy --noconfirm archlinux-keyring || \
sudo pacman -U --noconfirm https://archive.archlinux.org/packages/a/archlinux-keyring/archlinux-keyring-20260323-1-any.pkg.tar.zst

# Full system sync
sudo pacman -Syyu --noconfirm


echo "☕ Installing build dependencies..."

sudo pacman -S --noconfirm \
    jdk8-openjdk \
    ncurses \
    python


echo "⚙️ Setting Java 8..."

sudo archlinux-java set java-8-openjdk

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH


########################################################################################################





echo "✅ Environment ready for Android build!"













#m Bluetooth -j4 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload
make bacon -j3 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload

java -version
