sudo apt update
sudo apt install patchelf -y

rm -rf .repo/local_manifests/


#rm -rf hardware/dolby
#rm -rf packages/apps/Settings
#rm -rf packages/apps/Evolver
#rm -rf packages/apps/Evolver
# rm -rf bootable
# rm -rf build/make
# rm -rf frameworks/av
#rm -rf frameworks/base
# rm -rf hardware/google/pixel
# rm -rf hawrdware/interfaces
# rm -rf packages/modules/Bluetooth
#rm -rf vendor
#rm -rf TMP_PATCHES



#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
#repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --depth=1
git clone https://github.com/jayz1212/local --depth 1 -b lg .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags


/opt/crave/resync.sh




# rm -rf hardware/mediatek/interfaces/hardware/bluetooth
# rg -l -0 '<<<<<<<|=======|>>>>>>>' hardware/mediatek | xargs -0 sed -i '/^<<<<<<< /d;/^=======/d;/^>>>>>>> /d'
# #./device/xiaomi/blossom/applyPatches.sh device/xiaomi/blossom/patches

# export TARGET_USES_PICO_GAPPS=true
# export TARGET_ENABLE_BLUR=false
# export WITH_ADB_INSECURE=true
# export SELINUX_IGNORE_NEVERALLOWS=true
# export WITH_GMS=false
export CLANG_TARGET_ARM32="--target=arm-linux-android"
source build/envsetup.sh
#make clean


#export WITH_GMS=false
#rm -rf hardware/interfaces/biometrics/fingerprint/2.1/default


    
breakfast h872
brunch h872

#lunch lineage_h872-bp4a-eng
#make installclean
#make clean # one time
#m bacon
#m evolution



