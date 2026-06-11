rm -rf .repo/local_manifests/
rm -rf device/xiaomi
rm -rf kernel/xiaomi
rm -rf vendor/xiaomi
rm -rf hardware/xiaomi


# Clone DerpFest

repo init -u https://github.com/Evolution-X/manifest -b vic --depth=1 --git-lfs
#Temp Fix Repo tool
#cd .repo/repo;git pull -r;cd ../..;

# Clone local_manifests repository
git clone https://github.com/bagaskara815/local_manifests --depth 1 -b 15.2-old .repo/local_manifests
if [ ! 0 == 0 ]
 then   curl -o .repo/local_manifests https://github.com/bagaskara815/local_manifests.git
 fi

# repo sync
/opt/crave/resync.sh
grep -q '"com.lazada.android"' frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java || \
sed -i '/"com.android.chrome",/a\        "com.lazada.android",\n        "com.shopee.ph",' frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java
cat frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java

# # Set up build environment
# cd frameworks/base && curl https://gist.githubusercontent.com/bagaskara815/b2abdff48cae8370ca2a0b867d7769e4/raw/fw.patch >> fw.patch && git am fw.patch && rm fw.patch && cd ../../
# wget https://github.com/bagaskara815/local_manifests/raw/keys/keys.zip && unzip -o keys.zip -d vendor/lineage/signing/ && rm keys.zip

# # disable fsgen
# cd build/soong && curl https://gist.githubusercontent.com/bagaskara815/2f26516ef378fe8eae9803749e331a09/raw/fsgen.patch >> fsgen.patch && git am fsgen.patch && rm fsgen.patch && cd ../../

# # Nfc Fix
# cd packages/apps/Nfc && curl https://gist.githubusercontent.com/bagaskara815/e9ad53683e62a66ff0a4ba5d714bed80/raw/nfcfix.patch >> nfcfix.patch && git am nfcfix.patch && rm nfcfix.patch && cd ../../../

# # GMS temp fix
# cd vendor/google/gms && curl https://gist.githubusercontent.com/bagaskara815/eff6e36fb96db28298d35281eb2b85c4/raw/gms-temp-fix.patch >> gms-temp-fix.patch && git am gms-temp-fix.patch && rm gms-temp-fix.patch && cd ../../../

source build/envsetup.sh

# brunch configuration
lunch lineage_vayu-bp1a-userdebug

# Clean
make installclean

# Run
m evolution
