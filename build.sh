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
rm -rf hardware/dolby
rm -rf bootable
rm -rf build/make
rm -rf frameworks/av
rm -rf frameworks/base
rm -rf hardware/google/pixel
rm -rf hawrdware/interfaces
rm -rf packages/modules/Bluetooth
rm -rf vendor



repo init -u https://github.com/Evolution-X/manifest -b bq2 --depth=1 --git-lfs
git clone https://github.com/jayz1212/local --depth 1 -b cda13 .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags


/opt/crave/resync.sh



DEVICE_DIR="device/xiaomi/blossom/sepolicy/vendor"
FILE="$DEVICE_DIR/init.te"

echo "[*] Fixing sepolicy neverallow (mounton)..."

if [ ! -f "$FILE" ]; then
    echo "[!] File not found: $FILE"
    exit 1
fi

# Backup
cp "$FILE" "$FILE.bak"

# 1. Remove illegal mounton rules
sed -i '/volte_.*_exec.*mounton/d' "$FILE"

# 2. Add safe rules if not already present
grep -q "volte_imcb_exec:file" "$FILE" || cat >> "$FILE" <<EOF

# Auto-added safe VoLTE rules
allow init volte_imcb_exec:file { read open execute getattr };
allow init volte_stack_exec:file { read open execute getattr };
allow init volte_ua_exec:file { read open execute getattr };
EOF

echo "[✓] mounton rules removed and safe rules added"
rm -rf hardware/mediatek/interfaces/hardware/bluetooth
#./device/xiaomi/blossom/applyPatches.sh device/xiaomi/blossom/patches
source build/envsetup.sh

export TARGET_USES_PICO_GAPPS=true
export TARGET_ENABLE_BLUR=false
export WITH_GMS=false
rm -rf hardware/interfaces/biometrics/fingerprint/2.1/default

sed -i '\|$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)|d' device/xiaomi/blossom/lineage_blossom.mk
sed -i '/# FM Radio/,+2d' device/xiaomi/blossom/device.mk
sed -i 's/PRODUCT_BOOT_JARS +=/PRODUCT_PACKAGES +=/' device/xiaomi/blossom/device.mk
sed -i '/<<<<<<< HEAD/d;/=======/d;/>>>>>>>/d' device/xiaomi/blossom/rootdir/etc/fstab.mt6765

lunch lineage_blossom-bp4a-eng
m evolution
