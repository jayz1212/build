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
rm -rf hardware/interfaces/biometrics/fingerprint/2.1/default

sed -i '\|$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)|d' device/xiaomi/blossom/lineage_blossom.mk
sed -i '/# FM Radio/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# Besloudness/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# FM Radio/,/RevampedFMRadio/d' device/xiaomi/blossom/device.mk
sed -i '/<<<<<<< HEAD/d;/=======/d;/>>>>>>>/d' device/xiaomi/blossom/rootdir/etc/fstab.mt6765
sed -i '/dirty_writeback_centisecs/d' device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts
# sed -i '/system_server.*sys_module/d' device/mediatek/sepolicy_vndr/basic/non_plat/system_server.te
sed -i '/^persist.vendor.audio\.\s/d' device/xiaomi/blossom/sepolicy/vendor/property_contexts
sed -i '/ro.vendor.audio\./d' device/xiaomi/blossom/sepolicy/*/property_contexts

# DEVICE_DIR="device/xiaomi/blossom/sepolicy/vendor"
# FILE="$DEVICE_DIR/init.te"

# echo "[*] Fixing sepolicy neverallow (mounton)..."

# if [ ! -f "$FILE" ]; then
#     echo "[!] File not found: $FILE"
#     exit 1
# fi

# # Backup
# cp "$FILE" "$FILE.bak"

# # 1. Remove illegal mounton rules
# sed -i '/volte_.*_exec.*mounton/d' "$FILE"

# # 2. Add safe rules if not already present
# grep -q "volte_imcb_exec:file" "$FILE" || cat >> "$FILE" <<EOF

# # Auto-added safe VoLTE rules
# allow init volte_imcb_exec:file { read open execute getattr };
# allow init volte_stack_exec:file { read open execute getattr };
# allow init volte_ua_exec:file { read open execute getattr };
# EOF

# echo "[✓] mounton rules removed and safe rules added"


# FILE="packages/apps/Settings/Evolver/src/org/evolution/settings/fragments/miscellaneous/TrickyStoreAppPicker.kt"

# sed -i 's|import com.android.axion.compose.sheet.BottomSheetDialog|import androidx.compose.material3.ModalBottomSheet\nimport androidx.compose.material3.rememberModalBottomSheetState|' "$FILE"

# sed -i '/BottomSheetDialog(/,/){/c\
#         val sheetState = rememberModalBottomSheetState()\
# \
#         ModalBottomSheet(\
#             onDismissRequest = {\
#                 saveTargets()\
#                 onDismiss()\
#             },\
#             sheetState = sheetState\
#         ) {' "$FILE"


FILE=device/xiaomi/blossom/device.mk

grep -q "ro.adb.secure=0" "$FILE" || cat >> "$FILE" <<'EOF'

# Auto-added ADB debug props
PRODUCT_SYSTEM_PROPERTIES += \
    ro.adb.secure=0 \
    ro.secure=0 \
    ro.debuggable=1 \
    persist.sys.usb.config=mtp,adb

EOF

FIL=device/xiaomi/blossom/BoardConfig.mk
cat >> "$FIL" <<'EOF'



EOF
sed -i '/# IMS/,/mediatek-telephony-common/c\# IMS / MTK framework jars\
PRODUCT_SYSTEM_SERVER_JARS += \\\
    mediatek-framework \\\
    mediatek-telecom-common \\\
    mediatek-telephony-base\
\
PRODUCT_PACKAGES += \\\
    mediatek-common \\\
    mediatek-ims-base \\\
    mediatek-ims-common \\\
    mediatek-telephony-common' device/xiaomi/blossom/device.mk


#####################################################
# FULL BLOSSOM ANDROID16 FIX PACK (removes conflicting old libshims and keeps new shims)

rm -rf device/xiaomi/blossom/libshims
rm -rf device/xiaomi/blossom/shims
mkdir -p device/xiaomi/blossom/shims

# -------------------------------------------------------------------
# Android.bp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/Android.bp <<'EOF'
cc_library_shared {
    name: "libshim_base",
    vendor: true,
    compile_multilib: "both",
    srcs: ["libshim_base.cpp"],
    shared_libs: [
        "libbase",
        "liblog",
    ],
}

cc_library_shared {
    name: "libshim_taskprofile",
    vendor: true,
    compile_multilib: "both",
    srcs: ["libshim_taskprofile.cpp"],
    shared_libs: ["liblog"],
}

cc_library_shared {
    name: "libshim_processgroup",
    vendor: true,
    compile_multilib: "both",
    srcs: ["libshim_processgroup.cpp"],
    shared_libs: ["liblog"],
}

cc_library_shared {
    name: "libshim_audio",
    vendor: true,
    compile_multilib: "both",
    srcs: ["libshim_audio.cpp"],
    shared_libs: [
        "liblog",
        "libutils",
    ],
}

cc_library_shared {
    name: "libshim_vtservice",
    vendor: true,
    compile_multilib: "32",
    srcs: ["libshim_vtservice.cpp"],
    shared_libs: [
        "liblog",
        "libbinder",
        "libutils",
    ],
}

cc_prebuilt_library_shared {
    name: "libsink",
    vendor: true,
    compile_multilib: "32",
    srcs: ["proprietary/lib/libsink.so"],
    strip: {
        none: true,
    },
}
EOF

# -------------------------------------------------------------------
# libshim_base.cpp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/libshim_base.cpp <<'EOF'
#include <string>

namespace android {
namespace base {

std::string Basename(const std::string& path) {
    size_t p = path.find_last_of('/');
    if (p == std::string::npos) return path;
    return path.substr(p + 1);
}

}
}
EOF

# -------------------------------------------------------------------
# libshim_taskprofile.cpp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/libshim_taskprofile.cpp <<'EOF'
#include <stddef.h>

extern "C" int SetTaskProfiles(int, const int*, size_t, bool) {
    return 0;
}

extern "C" int SetProcessProfiles(int, const int*, size_t, bool) {
    return 0;
}
EOF

# -------------------------------------------------------------------
# libshim_processgroup.cpp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/libshim_processgroup.cpp <<'EOF'
extern "C" int set_cpuset_policy(int, int) {
    return 0;
}

extern "C" int set_sched_policy(int, int) {
    return 0;
}
EOF

# -------------------------------------------------------------------
# libshim_audio.cpp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/libshim_audio.cpp <<'EOF'
extern "C" void _ZN7android23AudioSystemCompatShimEv() {}

extern "C" int property_get(const char*, char*, const char*) {
    return 0;
}
EOF

# -------------------------------------------------------------------
# libshim_vtservice.cpp
# -------------------------------------------------------------------
cat > device/xiaomi/blossom/shims/libshim_vtservice.cpp <<'EOF'
extern "C" void _ZN7android10IInterfaceD0Ev() {}
EOF

# -------------------------------------------------------------------
# device.mk patch
# -------------------------------------------------------------------
grep -q "Final Android16 Blossom Fix Pack" device/xiaomi/blossom/device.mk || cat >> device/xiaomi/blossom/device.mk <<'EOF'

# Final Android16 Blossom Fix Pack
PRODUCT_PACKAGES += \
    libshim_base \
    libshim_taskprofile \
    libshim_processgroup \
    libshim_audio \
    libshim_vtservice \
    libsink

PRODUCT_PACKAGES_REMOVE += \
    audio.primary.default \
    android.hardware.biometrics.fingerprint@2.1-service
EOF

# -------------------------------------------------------------------
# BoardConfig.mk patch
# -------------------------------------------------------------------
sed -i '/TARGET_LD_SHIM_LIBS/,$d' device/xiaomi/blossom/BoardConfig.mk

cat >> device/xiaomi/blossom/BoardConfig.mk <<'EOF'

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
    /vendor/lib64/hw/audio.primary.mt6765.so|libshim_audio.so \
    /system_ext/lib/libimsma.so|libsink.so \
    /system_ext/lib/libimsma.so|libshim_vtservice.so

BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
TARGET_USES_64_BIT_BINDER := true
BOARD_USES_LEGACY_ALSA_AUDIO := true
BOARD_VNDK_VERSION := current
EOF

# -------------------------------------------------------------------
# sepolicy
# -------------------------------------------------------------------
mkdir -p device/xiaomi/blossom/sepolicy/vendor

cat > device/xiaomi/blossom/sepolicy/vendor/hal_fix.te <<'EOF'
allow hal_audio_default vendor_file:file { read open getattr map execute };
allow hal_audio_default self:process execmem;
allow hal_fingerprint_default self:process execmem;
allow hal_camera_default self:process execmem;

permissive hal_audio_default;
permissive hal_fingerprint_default;
EOF

# -------------------------------------------------------------------
# clean + build
# -------------------------------------------------------------------
rm -rf out/soong

echo "DONE."
echo "Now run:"
echo "make installclean"
echo "source build/envsetup.sh"
echo "lunch lineage_blossom-userdebug"
echo "mka bacon -j16"
#####################################


    

lunch lineage_blossom-bp4a-eng
make installclean
#make clean
m bacon
