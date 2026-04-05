# sudo apt update
# sudo apt install libncurses6 libncurses6:i386 libtinfo6 libtinfo6:i386

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
export CROSS_COMPILE=arm-linux-androideabi-
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

brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload


grep -F "sysfs /devices/platform/leds-mt65xx" out/soong/.intermediates/system/sepolicy/plat_sepolicy.cil/android_common/plat_sepolicy.cil 2>&1 | tee build.log
