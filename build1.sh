

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
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 --git-lfs

git clone https://github.com/jayz1212/local.git -b main .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

sed -i 's|PRODUCT_AAPT_CONFIG := normal hdpi xhdpi|PRODUCT_AAPT_CONFIG ?= normal hdpi xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
sed -i 's|PRODUCT_AAPT_PREF_CONFIG := xhdpi|PRODUCT_AAPT_PREF_CONFIG ?= xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
. build/envsetup.sh



curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/ril.sh | bash


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




source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/compilerfix.sh)

# curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/fixlib.sh | bash

wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb && sudo dpkg -i libtinfo5_6.3-2_amd64.deb && rm -f libtinfo5_6.3-2_amd64.deb
wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb && sudo dpkg -i libncurses5_6.3-2_amd64.deb && rm -f libncurses5_6.3-2_amd64.deb


source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/4ff76f942afb63b356034ad5e4068bb41d7781c8/fixsap.sh)
#source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/java2.sh | bash)


. build/envsetup.sh
lunch lineage_a5ltechn-userdebug
echo "☕ Forcing Java 8 (hard override)..."

# JDK8="/usr/lib/jvm/java-8-openjdk"

# export JAVA_HOME="$JDK8"
# export PATH="$JAVA_HOME/bin:$PATH"

# 🔥 HARD FIX
# ln -sf $JDK8/bin/java prebuilts/jdk/jdk9/linux-x86/bin/java

# hash -r

# which java
# java -version

# CLEAN AFTER FIX
rm -rf out/soong/.intermediates
rm -rf out/soong/.intermediates/frameworks/base
rm -rf out/soong/.intermediates/libcore
rm -rf out/soong/.intermediates/frameworks/base/api*
# build
make clean
#m Bluetooth -j4 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload
make framework -j6 2>&1 | tee build.log && curl -F "file=@build.log" https://temp.sh/upload

java -version
