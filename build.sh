rm -rf .repo/local_manifests
rm -rf hardware/xiaomi
rm -rf device/xiaomi
rm -rf vendor/xiaomi
rm -rf vendor/lineage-priv
rm -rf kernel/xiaomi
rm -rf frameworks/base
repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs
git clone https://github.com/vayu-development-sources/local_manifests.git -b evo15-dolby .repo/local_manifests
/opt/crave/resync.sh
git clone https://gitlab.com/ArmSM/vendor_xiaomi_miuicamera.git vendor/xiaomi/miuicamera

cd frameworks/base/
git fetch https://github.com/xc112lg/android_frameworks_base.git patch-2
git cherry-pick 3a3b3718ffcfe53127cbfa228577f02d825e1960
cd -
. build/envsetup.sh && lunch lineage_vayu-ap4a-user && m evolution
