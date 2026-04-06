

#!/usr/bin/env bash

wget https://download.java.net/java/GA/jdk9/9/binaries/openjdk-9_linux-x64_bin.tar.gz && \
tar -xvf openjdk-9_linux-x64_bin.tar.gz && \
sudo mv jdk-9 /opt/jdk-9 && \
sudo update-alternatives --install /usr/bin/java java /opt/jdk-9/bin/java 1 && \
sudo update-alternatives --install /usr/bin/javac javac /opt/jdk-9/bin/javac 1 && \
echo 'export JAVA_HOME=/opt/jdk-9' >> ~/.bashrc && \
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc && \
export JAVA_HOME=/opt/jdk-9 && \
export PATH=$JAVA_HOME/bin:$PATH && \
java -version


sudo apt update
sudo apt install python-is-python3 -y
sudo apt install libncurses6 libtinfo6 -y
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

export PYTHON=python3.10
export PYTHON=python3
sudo rm -rf src/android

rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung
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
curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/fixsap.sh | bash
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
export CROSS_COMPILE=prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-


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
sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5

echo 'LOCAL_SRC_FILES := $(filter-out %/sap/%, $(LOCAL_SRC_FILES))' >> packages/apps/Bluetooth/Android.mk
. build/envsetup.sh
brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload
