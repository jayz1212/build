# sudo apt update
# sudo apt install libncurses6 libncurses6:i386 libtinfo6 libtinfo6:i386

# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# # For 32-bit (needed for renderscript compilation)
# sudo ln -s /usr/lib/i386-linux-gnu/libncurses.so.6 /usr/lib/i386-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/i386-linux-gnu/libtinfo.so.6 /usr/lib/i386-linux-gnu/libtinfo.so.5

# ls -la /usr/lib/x86_64-linux-gnu/libncurses.so.5
# ls -la /usr/lib/i386-linux-gnu/libncurses.so.5

rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung


repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 --git-lfs

git clone https://github.com/jayz1212/local.git -b main .repo/local_manifests
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
/opt/crave/resync.sh

sed -i 's|PRODUCT_AAPT_CONFIG := normal hdpi xhdpi|PRODUCT_AAPT_CONFIG ?= normal hdpi xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
sed -i 's|PRODUCT_AAPT_PREF_CONFIG := xhdpi|PRODUCT_AAPT_PREF_CONFIG ?= xhdpi|' device/samsung/a5-common/BoardConfigCommon.mk
. build/envsetup.sh
set -e

echo "[*] Disabling RIL completely..."

DEVICE_DIR="device/samsung/a5ltechn"
COMMON_DIR="device/samsung/msm8916-common"

# -----------------------------
# 1. Remove libril from device.mk
# -----------------------------
for FILE in $(find $DEVICE_DIR $COMMON_DIR -name "device.mk" 2>/dev/null); do
    echo "[*] Processing $FILE"

    sed -i '/libril/d' "$FILE"
    sed -i '/librilutils/d' "$FILE"
done

echo "[+] Removed libril from PRODUCT_PACKAGES"

# -----------------------------
# 2. Add ro.radio.noril=true
# -----------------------------
for FILE in $(find $DEVICE_DIR $COMMON_DIR -name "device.mk" 2>/dev/null); do
    if ! grep -q "ro.radio.noril=true" "$FILE"; then
        echo "" >> "$FILE"
        echo "# Disable RIL" >> "$FILE"
        echo "PRODUCT_PROPERTY_OVERRIDES += ro.radio.noril=true" >> "$FILE"
        echo "[+] Added ro.radio.noril=true to $FILE"
    fi
done

# -----------------------------
# 3. Disable ril-daemon in init.rc
# -----------------------------
for FILE in $(find $DEVICE_DIR $COMMON_DIR -name "init*.rc" 2>/dev/null); do
    echo "[*] Patching $FILE"

    sed -i 's/^service ril-daemon/# service ril-daemon/g' "$FILE"
    sed -i 's/^service ril-daemon1/# service ril-daemon1/g' "$FILE"
done

echo "[+] Disabled ril-daemon services"

# -----------------------------
# 4. Remove rild.libpath props
# -----------------------------
for FILE in $(find $DEVICE_DIR $COMMON_DIR -name "*.prop" 2>/dev/null); do
    sed -i '/rild.libpath/d' "$FILE"
    sed -i '/rild.libpath2/d' "$FILE"
done

echo "[+] Removed rild.libpath properties"

# -----------------------------
# 5. Optional: remove telephony apps
# -----------------------------
for FILE in $(find $DEVICE_DIR $COMMON_DIR -name "device.mk" 2>/dev/null); do
    sed -i '/TeleService/d' "$FILE"
    sed -i '/Stk/d' "$FILE"
done

echo "[+] Removed Telephony apps"

# -----------------------------
# DONE
# -----------------------------
echo "[✔] RIL fully disabled!"
echo ""
echo "👉 Now run:"
echo "make clean && make -j\$(nproc)"



brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload


grep -F "sysfs /devices/platform/leds-mt65xx" out/soong/.intermediates/system/sepolicy/plat_sepolicy.cil/android_common/plat_sepolicy.cil 2>&1 | tee build.log
