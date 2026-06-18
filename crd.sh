sudo apt update
sudo apt install patchelf -y
sudo apt install ccache -y
mkdir tmp
export CCACHE_DIR=tmp
export USE_CCACHE=1
ccache -s
rm -rf .repo/local_manifests/
rm -rf device/xiaomi
rm -rf device/xiaomi/blossom-kernel
rm -rf vendor/xiaomi
rm -rf vendor/xiaomi/miuicamera
rm -rf hardware/mediatek
rm -rf device/mediatek/sepolicy_vndr
rm -rf TMP_PATCHES
#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs --depth=1
#repo init -u https://github.com/Lunaris-AOSP/android -b 16.2 --depth=1 --git-lfs
git clone https://github.com/jayz1212/local --depth 1 -b cd16 .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh
#export TARGET_USES_MINI_GAPPS=true
export TARGET_USES_PICO_GAPPS=true
export TARGET_ENABLE_BLUR=false
export SELINUX_IGNORE_NEVERALLOWS=true
export WITH_GMS=true
export TARGET_PERMISSIVE=true

#sed -i '/<item>com.android.nfc<\/item>/d' frameworks/base/core/res/res/values/policy_exempt_apps.xml
cat frameworks/base/core/res/res/values/policy_exempt_apps.xml
git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
chmod +x keys.sh
./keys.sh
cd -
source build/envsetup.sh
lunch lineage_blossom-bp4a-user
make installclean
#make clean # one time
#m bacon
m evolution
ccache -s
curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/tar.sh | bash
