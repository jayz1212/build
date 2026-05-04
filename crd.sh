sudo apt update
sudo apt install patchelf -y

rm -rf .repo/local_manifests/
rm -rf .repo/manifests/
rm -rf device/xiaomi
rm -rf device/xiaomi/blossom-kernel
rm -rf vendor/xiaomi
rm -rf vendor/xiaomi/miuicamera
rm -rf hardware/mediatek
rm -rf device/mediatek/sepolicy_vndr
#rm -rf hardware/dolby
#rm -rf packages/apps/Settings
#rm -rf packages/apps/Evolver
#rm -rf packages/apps/Evolver
# rm -rf bootable
# rm -rf build/make
# rm -rf frameworks/av
# rm -rf frameworks/base
# rm -rf hardware/google/pixel
# rm -rf hawrdware/interfaces
# rm -rf packages/modules/Bluetooth
#rm -rf vendor
#rm -rf TMP_PATCHES



repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --depth=1 --git-lfs
git clone https://github.com/jayz1212/local --depth 1 -b cd16 .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags


/opt/crave/resync.sh




rm -rf hardware/mediatek/interfaces/hardware/bluetooth
rg -l -0 '<<<<<<<|=======|>>>>>>>' hardware/mediatek | xargs -0 sed -i '/^<<<<<<< /d;/^=======/d;/^>>>>>>> /d'
#./device/xiaomi/blossom/applyPatches.sh device/xiaomi/blossom/patches

export TARGET_USES_PICO_GAPPS=true
export TARGET_ENABLE_BLUR=false
export WITH_ADB_INSECURE=true
export SELINUX_IGNORE_NEVERALLOWS=true
export WITH_GMS=false
source build/envsetup.sh
#make clean
git clone https://github.com/jayz1212/v30 --depth 1 -b main prebuilts/vndk/v30/

#export WITH_GMS=false
#rm -rf hardware/interfaces/biometrics/fingerprint/2.1/default

sed -i '\|$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)|d' device/xiaomi/blossom/lineage_blossom.mk
sed -i '/# FM Radio/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# Besloudness/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# FM Radio/,/RevampedFMRadio/d' device/xiaomi/blossom/device.mk
sed -i '/<<<<<<< HEAD/d;/=======/d;/>>>>>>>/d' device/xiaomi/blossom/rootdir/etc/fstab.mt6765
sed -i '/<<<<<<< HEAD/d;/=======/d;/>>>>>>>/d' device/xiaomi/blossom/BoardConfig.mk
sed -i '/dirty_writeback_centisecs/d' device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts
# sed -i '/system_server.*sys_module/d' device/mediatek/sepolicy_vndr/basic/non_plat/system_server.te
sed -i '/^persist.vendor.audio\.\s/d' device/xiaomi/blossom/sepolicy/vendor/property_contexts
sed -i '/ro.vendor.audio\./d' device/xiaomi/blossom/sepolicy/*/property_contexts


########################################################
sed -i 's/PRODUCT_BOOT_JARS +=/PRODUCT_PACKAGES +=/' device/xiaomi/blossom/device.mk
#####################################

echo "== Blossom Android 16 Shim Fix =="

DT=device/xiaomi/blossom

# ------------------------------------------------
# 1. Remove broken libbase shim
# ------------------------------------------------
echo "[1] Removing broken libbase shim..."
rm -rf $DT/libshims/libbase || true

# ------------------------------------------------
# 2. Create correct libshim_base
# ------------------------------------------------
echo "[2] Creating correct libshim_base..."

cat > $DT/libshims/libshim_base.cpp <<'EOF'
#include <string>

namespace android {
namespace base {

std::string Basename(const std::string& path) {
    size_t pos = path.find_last_of("/\\");
    if (pos == std::string::npos) return path;
    return path.substr(pos + 1);
}

} // namespace base
} // namespace android
EOF

# ------------------------------------------------
# 3. Fix Android.bp
# ------------------------------------------------
echo "[3] Fixing Android.bp..."

BP=$DT/libshims/Android.bp

# Remove old libshim_base block
sed -i '/name: "libshim_base"/,/}/d' $BP

# Append correct one
cat >> $BP <<'EOF'

cc_library_shared {
    name: "libshim_base",
    vendor: true,
    srcs: ["libshim_base.cpp"],
    shared_libs: ["liblog"],
    stl: "none",
}
EOF

# ------------------------------------------------
# 4. Fix taskprofile shim
# ------------------------------------------------
echo "[4] Fixing taskprofile shim..."

cat > $DT/libshims/libshim_taskprofile.cpp <<'EOF'
extern "C" void SetTaskProfiles(int tid, const char* profiles) {
    // stub
}
EOF

# ------------------------------------------------
# 5. Fix audio shim (minimal safe stub)
# ------------------------------------------------
echo "[5] Fixing audio shim..."

cat > $DT/libshims/libshim_audio.cpp <<'EOF'
extern "C" void _ZN7androidAudioSystem15getOutputLatencyEPj19audio_stream_type() {}
EOF

# ------------------------------------------------
# 6. Clean lineage_blossom.mk
# ------------------------------------------------
echo "[6] Cleaning PRODUCT_PACKAGES..."

MK=$DT/lineage_blossom.mk

sed -i '/libshim_beanpod/d' $MK || true
sed -i '/libshim_sensors/d' $MK || true
sed -i '/libshim_ui/d' $MK || true

# ------------------------------------------------
# 7. Fix BoardConfig.mk
# ------------------------------------------------
echo "[7] Rewriting TARGET_LD_SHIM_LIBS..."

BC=$DT/BoardConfig.mk

sed -i '/TARGET_LD_SHIM_LIBS/,$d' $BC

cat >> $BC <<'EOF'

# Final linker shims
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libnvram.so|libshim_base.so \
    /vendor/lib64/libnvram.so|libshim_base.so \
    /vendor/lib/libsysenv.so|libshim_base.so \
    /vendor/lib64/libsysenv.so|libshim_base.so \
    /vendor/lib/libutils-v30.so|libshim_taskprofile.so \
    /vendor/lib64/libutils-v30.so|libshim_taskprofile.so \
    /vendor/lib/libprocessgroup.so|libshim_processgroup.so \
    /vendor/lib64/libprocessgroup.so|libshim_processgroup.so \
    /vendor/lib/hw/audio.primary.mt6765.so|libshim_audio.so \
    /vendor/lib64/hw/audio.primary.mt6765.so|libshim_audio.so

BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
TARGET_USES_64_BIT_BINDER := true
BOARD_USES_LEGACY_ALSA_AUDIO := true
BOARD_VNDK_VERSION := current
EOF

# ------------------------------------------------
# DONE
# ------------------------------------------------
echo "========================================"
echo "✔ Fix applied successfully"
echo "Now run:"
echo "  mka clean"
echo "  mka bacon"
echo "========================================"

#######################################################

    

lunch lineage_blossom-bp4a-eng
make installclean

m bacon
