

#!/usr/bin/env bash


echo "🔥 FULL AUTO FIX STARTING..."

# -------------------------------

# 1. Fix pacman keyring (force clean)

# -------------------------------

echo "🔑 Fixing pacman keys..."
sudo rm -rf /etc/pacman.d/gnupg || true
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Update keyring first (critical)

sudo pacman -Sy --noconfirm archlinux-keyring

# -------------------------------

# 2. Fix mirrors (fast + reliable)

# -------------------------------

echo "🌐 Refreshing mirrors..."
sudo pacman -S --noconfirm reflector
sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# -------------------------------

# 3. Full system update

# -------------------------------

echo "📦 Updating system..."
sudo pacman -Syyu --noconfirm

# -------------------------------

# 4. Install Java 8

# -------------------------------

echo "☕ Installing Java 8..."
sudo pacman -S --noconfirm jdk8-openjdk

# -------------------------------

# 5. Switch to Java 8

# -------------------------------

echo "🔄 Switching to Java 8..."
sudo archlinux-java set java-8-openjdk

# Verify

java -version

# -------------------------------

# 6. Export env (extra safety)

# -------------------------------

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# -------------------------------

# 7. Clean broken Android build

# -------------------------------

echo "🧹 Cleaning broken intermediates..."
rm -rf out/soong/.intermediates/libcore || true
rm -rf out/soong/.intermediates/frameworks || true
rm -rf out/soong/.intermediates/external/v8 || true

# -------------------------------

# 8. Build

# -------------------------------

echo "🚀 Rebuilding..."



# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# # For 32-bit (needed for renderscript compilation)
# sudo ln -s /usr/lib/i386-linux-gnu/libncurses.so.6 /usr/lib/i386-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/i386-linux-gnu/libtinfo.so.6 /usr/lib/i386-linux-gnu/libtinfo.so.5

# ls -la /usr/lib/x86_64-linux-gnu/libncurses.so.5
# ls -la /usr/lib/i386-linux-gnu/libncurses.so.5

rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung


repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 --git-lfs

git clone https://github.com/jayz1212/local.git -b main .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

sed -i 's|PRODUCT_AAPT_CONFIG := normal hdpi xhdpi|PRODUCT_AAPT_CONFIG ?= normal hdpi xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
sed -i 's|PRODUCT_AAPT_PREF_CONFIG := xhdpi|PRODUCT_AAPT_PREF_CONFIG ?= xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
. build/envsetup.sh

# set -e

# BASE="hardware/samsung/ril/libsecril-client"
# INCLUDE_PATH="hardware/samsung/ril/libril/include"

# echo "[*] Fixing ril_vendor.h include..."

# # --- ANDROID.MK ---
# if [ -f "$BASE/Android.mk" ]; then
#     echo "[*] Found Android.mk"

#     if grep -q "$INCLUDE_PATH" "$BASE/Android.mk"; then
#         echo "[✓] Include path already exists (Android.mk)"
#     else
#         echo "[*] Patching Android.mk..."

#         sed -i '/LOCAL_C_INCLUDES +=/a\    '"$INCLUDE_PATH" "$BASE/Android.mk"

#         echo "[✓] Patched Android.mk"
#     fi
# fi

# # --- ANDROID.BP ---
# if [ -f "$BASE/Android.bp" ]; then
#     echo "[*] Found Android.bp"

#     if grep -q "$INCLUDE_PATH" "$BASE/Android.bp"; then
#         echo "[✓] Include path already exists (Android.bp)"
#     else
#         echo "[*] Patching Android.bp..."

#         sed -i '/include_dirs: \[/a\        "'"$INCLUDE_PATH"'",' "$BASE/Android.bp"

#         echo "[✓] Patched Android.bp"
#     fi
# fi

# echo "[✓] Done fixing ril_vendor.h include!"

#curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/ril.sh | bash

curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/ril.sh | bash
export ARCH=arm
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export STRIP=llvm-strip
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf
export HOSTCC=clang
export HOSTCXX=clang++
export CLANG_TRIPLE=arm-linux-gnueabi-
export PATH_OVERRIDE_SOONG="prebuilts/build-tools/path/linux-x86/path_override"
export SUBARCH=arm
export CROSS_COMPILE=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

# # Disable stack protector
# scripts/config --disable CC_STACKPROTECTOR
# scripts/config --disable CC_STACKPROTECTOR_STRONG
# scripts/config --disable CC_STACKPROTECTOR_REGULAR

. build/envsetup.sh
brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload


grep -F "sysfs /devices/platform/leds-mt65xx" out/soong/.intermediates/system/sepolicy/plat_sepolicy.cil/android_common/plat_sepolicy.cil 2>&1 | tee build.log
