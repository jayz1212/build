




rm -rf .repo/local_manifests/

#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs --depth=1
# repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs --depth=1
git clone https://github.com/jayz1212/local --depth 1 -b lg .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh
# export TARGET_USES_PICO_GAPPS=true
# export TARGET_ENABLE_BLUR=false
# export WITH_ADB_INSECURE=true
# export SELINUX_IGNORE_NEVERALLOWS=true
export WITH_GMS=false
export TARGET_USES_PICO_GAPPS=true
export CLANG_TARGET_ARM32="--target=arm-linux-android"

source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/lg/a.sh)  >/dev/null 2>&1
source build/envsetup.sh





perl -0777 -pi -e 's/^cc_prebuilt_library_shared \{\n\tname: "libwifi-hal-ctrl",.*?\n\}\n\n?//ms' vendor/lge/msm8996-common/Android.bp
sed -i '/^vendor\/lib\/libwifi-hal-ctrl\.so|/s/^/-/' device/lge/msm8996-common/proprietary-files.txt
sed -i '/^vendor\/lib64\/libwifi-hal-ctrl\.so|/s/^/-/' device/lge/msm8996-common/proprietary-files.txt
#lunch lineage_h872-bp1a-userdebug
lunch lineage_h872-bp4a-userdebug


make installclean
m evolution

# lunch lineage_h870-bp1a-userdebug

# make installclean
# m evolution -j64

# lunch lineage_us997-bp1a-userdebug

# make installclean
# m evolution -j64

#lunch lineage_h872-bp4a-eng
#make installclean
#make clean # one time
#m bacon
#m evolution



