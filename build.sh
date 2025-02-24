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
cd device/xiaomi/vayu
git fetch https://github.com/jayz1212/device_xiaomi_vayu.git patch-1
git cherry-pick eabc02b7c8c3d6669646770ceab08c37df3c5c9a
cd -

. build/envsetup.sh && lunch lineage_vayu-ap4a-user && m evolution


rm -rf Evolution-X
git clone https://$GH_TOKEN@github.com/xc112lg/Evolution-X.git
rm Evolution-X/*.zip

cp -r out/target/product/*/*.zip out/target/product/*/recovery.img Evolution-X/
cd Evolution-X/
chmod +x multi_upload.sh
. multi_upload.sh
