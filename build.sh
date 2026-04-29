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



repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
git clone https://github.com/jayz1212/local --depth 1 -b cda13 .repo/local_manifests
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
rm -rf packages/apps/DolbyAtmos
#export WITH_GMS=false
rm -rf hardware/interfaces/biometrics/fingerprint/2.1/default

sed -i '\|$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)|d' device/xiaomi/blossom/lineage_blossom.mk
sed -i '/# FM Radio/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# Besloudness/,+2d' device/xiaomi/blossom/device.mk
sed -i '/# FM Radio/,/RevampedFMRadio/d' device/xiaomi/blossom/device.mk
sed -i '/<<<<<<< HEAD/d;/=======/d;/>>>>>>>/d' device/xiaomi/blossom/rootdir/etc/fstab.mt6765
#sed -i '/dirty_writeback_centisecs/d' device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts
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

BUILD_BROKEN_MISSING_REQUIRED_MODULES := true

EOF

lunch lineage_blossom-bp4a-eng
#m installclean

m evolution 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload
