#!/usr/bin/env bash
rm -rf device/samsung
##set -e
sudo apt update
sudo apt install openjdk-8-jdk
# ===== CONFIG =====
TWRP_BRANCH="twrp-11"
DEVICE="a5ltechn"
JOBS=$(nproc --all)

echo "======================================="
echo "   TWRP Auto Build Script (A5 2015)"
echo "======================================="
echo

# ===== CLEAN (optional) =====
# rm -rf .repo out

# ===== INIT TWRP SOURCE =====
if [ ! -d ".repo" ]; then
    echo "📥 Initializing TWRP source..."
   repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-7.1
fi

# ===== SYNC =====
echo "🔄 Syncing source..."
repo sync -c -j64 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

# ===== CLONE DEVICE TREES =====
echo "📦 Cloning device trees..."


git clone --depth=1 https://github.com/xc112lg/android_device_samsung_a5ltechn -b main device/samsung/a5ltechn

echo "✅ Cloning done!"
echo
# sed -i 's|vendor/omni/config/common.mk|vendor/twrp/config/common.mk|g' device/samsung/a5-common/*.mk
# sed -i 's|$(call inherit-product, vendor/omni/config/gsm.mk)||g' device/samsung/a5-common/*.mk
# cat > device/samsung/a5-common/board/display.mk << 'EOF'
# # Screen density
# # handled by build system
# EOF
# ===== BUILD ENV =====
echo "⚙️ Setting up build environment..."
source build/envsetup.sh



#git clone --depth=1 https://github.com/omnirom/android_vendor_omni -b android-10 vendor/omni
lunch omni_${DEVICE}-eng
# ===== BUILD =====
echo "🛠️ Building TWRP..."
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
jave -version
mka recoveryimage -j$JOBS 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

# ===== DONE =====
echo
echo "======================================="
echo "✅ BUILD COMPLETE!"
echo "📍 Output:"
echo "out/target/product/${DEVICE}/recovery.img"
echo "======================================="
# ===== LUNCH =====
echo "🍱 Lunching device..."


