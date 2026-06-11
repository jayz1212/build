sudo apt update
sudo apt install patchelf -y
sudo apt install ccache -y
mkdir tmp
export CCACHE_DIR=tmp
export USE_CCACHE=1
ccache -s
rm -rf .repo/local_manifests/
rm -rf .repo/manifests/
rm -rf device/xiaomi
rm -rf device/xiaomi/blossom-kernel
rm -rf vendor/xiaomi
rm -rf vendor/xiaomi/miuicamera
rm -rf hardware/mediatek
rm -rf device/mediatek/sepolicy_vndr
rm -rf TMP_PATCHES
#repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
git clone https://github.com/jayz1212/local --depth 1 -b cd16 .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh
#export TARGET_USES_MINI_GAPPS=true
#export TARGET_USES_PICO_GAPPS=true
export TARGET_ENABLE_BLUR=false
export SELINUX_IGNORE_NEVERALLOWS=true
export WITH_GMS=false
export TARGET_PERMISSIVE=true
source build/envsetup.sh
lunch lineage_blossom-bp4a-eng
make installclean
#make clean # one time
#m bacon
m evolution
ccache -s
#curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/tar.sh | bash








echo "machine gitlab.com" >> ~/.netrc
echo "login dtiven13" >> ~/.netrc
export PASS=$(cat pass.txt)
echo "$PASS" >> ~/.netrc
chmod 600 ~/.netrc  # Important: strict permissions required
rm -rf crdroid10  # Backup your ZIP file first!
git clone https://gitlab.com/dtiven13/Test3.git crdroid10
cd crdroid10
rm -rf *.zip
git add .
git commit -m "Add ROM zip via LFS"

# Push
git push origin main
cd -


cd crdroid10

# Setup LFS
sudo apt update
sudo apt install git-lfs -y
git lfs install
git lfs track "*.zip"
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git add .gitattributes
git commit -m "Enable LFS"
git config --global http.version HTTP/1.1
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global lfs.concurrenttransfers 1
cd ..
cp out/target/product/*/recovery.img crdroid10
cp out/target/product/*/*.zip crdroid10


cd crdroid10
git add .
git commit -m "Add ROM zip via LFS"

# Push
git push origin main
