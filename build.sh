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

#!/bin/bash

set -e

RIL_DIR="hardware/samsung/ril/libril/include/telephony"
AOSP_RIL="hardware/ril/include/telephony/ril.h"

echo "[*] Applying Samsung RIL patch..."

# ✅ 1. Create ril_vendor.h
mkdir -p "$RIL_DIR"

cat > "$RIL_DIR/ril_vendor.h" <<'EOF'
#ifndef RIL_VENDOR_H
#define RIL_VENDOR_H

/* Samsung RIL v3 vendor extensions (MSM8916 era) */

#define RIL_REQUEST_GET_BARCODE_NUMBER                11000
#define RIL_REQUEST_UICC_GBA_AUTHENTICATE_BOOTSTRAP   11001
#define RIL_REQUEST_UICC_GBA_AUTHENTICATE_NAF         11002
#define RIL_REQUEST_SIM_TRANSMIT_BASIC                11003
#define RIL_REQUEST_SIM_TRANSMIT_CHANNEL              11004
#define RIL_REQUEST_SIM_AUTH                          11005
#define RIL_REQUEST_PS_ATTACH                         11006
#define RIL_REQUEST_PS_DETACH                         11007
#define RIL_REQUEST_ACTIVATE_DATA_CALL                11008
#define RIL_REQUEST_CHANGE_SIM_PERSO                  11009
#define RIL_REQUEST_ENTER_SIM_PERSO                   11010
#define RIL_REQUEST_GET_TIME_INFO                     11011
#define RIL_REQUEST_OMADM_SETUP_SESSION               11012
#define RIL_REQUEST_OMADM_SERVER_START_SESSION        11013
#define RIL_REQUEST_OMADM_CLIENT_START_SESSION        11014
#define RIL_REQUEST_OMADM_SEND_DATA                   11015
#define RIL_REQUEST_CDMA_GET_DATAPROFILE              11016
#define RIL_REQUEST_CDMA_SET_DATAPROFILE              11017
#define RIL_REQUEST_CDMA_GET_SYSTEMPROPERTIES         11018

#endif // RIL_VENDOR_H
EOF

echo "[+] ril_vendor.h created"

# ✅ 2. Patch ril_commands_vendor.h
RCV="$RIL_DIR/ril_commands_vendor.h"

if ! grep -q 'ril_vendor.h' "$RCV"; then
    sed -i '1i #include "ril_vendor.h"' "$RCV"
    echo "[+] ril_commands_vendor.h patched"
else
    echo "[=] ril_commands_vendor.h already patched"
fi

# ✅ 3. Patch AOSP ril.h (safe inject)
if [ -f "$AOSP_RIL" ]; then
    if ! grep -q 'ril_vendor.h' "$AOSP_RIL"; then
        sed -i '/#include <telephony\/ril.h>/a #include "ril_vendor.h"' "$AOSP_RIL" || true
        sed -i '1i #include "ril_vendor.h"' "$AOSP_RIL"
        echo "[+] ril.h patched"
    else
        echo "[=] ril.h already patched"
    fi
fi

# ✅ 4. Fix include priority (Android.mk)
MK_FILE="hardware/samsung/ril/libril/Android.mk"

if [ -f "$MK_FILE" ]; then
    if ! grep -q 'include/telephony' "$MK_FILE"; then
        sed -i '/LOCAL_C_INCLUDES +=/a \ \ \ \ $(LOCAL_PATH)/include/telephony \\' "$MK_FILE"
        echo "[+] Android.mk include path fixed"
    else
        echo "[=] Android.mk already contains include fix"
    fi
fi

echo "[✔] Samsung RIL patch applied successfully!"



brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload


grep -F "sysfs /devices/platform/leds-mt65xx" out/soong/.intermediates/system/sepolicy/plat_sepolicy.cil/android_common/plat_sepolicy.cil 2>&1 | tee build.log
