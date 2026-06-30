
git clone https://github.com/xc112lg/rbe1 >/dev/null 2>&1

source <(curl -sf https://raw.githubusercontent.com/xc112lg/scripts/refs/heads/lunaris/rbe2.sh)  >/dev/null 2>&1

rm -rf .repo/local_manifests/

#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
#repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --depth=1
git clone https://github.com/jayz1212/local --depth 1 -b lg .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh
# export TARGET_USES_PICO_GAPPS=true
# export TARGET_ENABLE_BLUR=false
# export WITH_ADB_INSECURE=true
# export SELINUX_IGNORE_NEVERALLOWS=true
# export WITH_GMS=false
export CLANG_TARGET_ARM32="--target=arm-linux-android"
source build/envsetup.sh





    
breakfast h872
brunch h872

#lunch lineage_h872-bp4a-eng
#make installclean
#make clean # one time
#m bacon
#m evolution



