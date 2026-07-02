
git clone https://github.com/xc112lg/rbe1 >/dev/null 2>&1



rm -rf .repo/local_manifests/

#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
#repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs --depth=1
git clone https://github.com/jayz1212/local --depth 1 -b lg .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh
# export TARGET_USES_PICO_GAPPS=true
# export TARGET_ENABLE_BLUR=false
# export WITH_ADB_INSECURE=true
# export SELINUX_IGNORE_NEVERALLOWS=true
export WITH_GMS=true
export TARGET_USES_PICO_GAPPS=true
export CLANG_TARGET_ARM32="--target=arm-linux-android"
source <(curl -sf https://raw.githubusercontent.com/xc112lg/scripts/refs/heads/lunaris/rbe2.sh)  >/dev/null 2>&1
source build/envsetup.sh






breakfast h872
make installclean
brunch h872
curl -sf https://raw.githubusercontent.com/xc112lg/evolutiion_lgg6/refs/heads/main/upevo.sh | bash 
#lunch lineage_h872-bp4a-eng
#make installclean
#make clean # one time
#m bacon
#m evolution



