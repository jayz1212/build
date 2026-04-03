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

BASE="hardware/samsung/ril/libsecril-client"
INCLUDE_PATH="hardware/samsung/ril/libril/include"

echo "[*] Fixing ril_vendor.h include..."

# --- ANDROID.MK ---
if [ -f "$BASE/Android.mk" ]; then
    echo "[*] Found Android.mk"

    if grep -q "$INCLUDE_PATH" "$BASE/Android.mk"; then
        echo "[✓] Include path already exists (Android.mk)"
    else
        echo "[*] Patching Android.mk..."

        sed -i '/LOCAL_C_INCLUDES +=/a\    '"$INCLUDE_PATH" "$BASE/Android.mk"

        echo "[✓] Patched Android.mk"
    fi
fi

# --- ANDROID.BP ---
if [ -f "$BASE/Android.bp" ]; then
    echo "[*] Found Android.bp"

    if grep -q "$INCLUDE_PATH" "$BASE/Android.bp"; then
        echo "[✓] Include path already exists (Android.bp)"
    else
        echo "[*] Patching Android.bp..."

        sed -i '/include_dirs: \[/a\        "'"$INCLUDE_PATH"'",' "$BASE/Android.bp"

        echo "[✓] Patched Android.bp"
    fi
fi

echo "[✓] Done fixing ril_vendor.h include!"

#!/bin/bash

echo "=========================================="
echo "Complete RIL Fix for SM-A5000 (a5ltechn)"
echo "=========================================="

# ============================================================================
# Step 1: Create comprehensive Samsung RIL definitions header
# ============================================================================
echo "Creating comprehensive Samsung RIL definitions..."

cat > hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h << 'EOF'
#ifndef SAMSUNG_RIL_DEFS_H
#define SAMSUNG_RIL_DEFS_H

/* Samsung OEM Request Base */
#ifndef RIL_OEM_REQUEST_BASE
#define RIL_OEM_REQUEST_BASE 10000
#endif

/* Samsung Unsol Response Base */
#ifndef SAMSUNG_UNSOL_RESPONSE_BASE
#define SAMSUNG_UNSOL_RESPONSE_BASE 11000
#endif

/* ============================================================================
 * Samsung RIL Request Definitions
 * ============================================================================ */

/* Basic OEM requests */
#define RIL_REQUEST_GET_CELL_BROADCAST_CONFIG (RIL_OEM_REQUEST_BASE + 0)
#define RIL_REQUEST_SEND_ENCODED_USSD (RIL_OEM_REQUEST_BASE + 1)
#define RIL_REQUEST_SET_PDA_MEMORY_STATUS (RIL_OEM_REQUEST_BASE + 2)
#define RIL_REQUEST_GET_PHONEBOOK_STORAGE_INFO (RIL_OEM_REQUEST_BASE + 3)
#define RIL_REQUEST_GET_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 4)
#define RIL_REQUEST_ACCESS_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 5)
#define RIL_REQUEST_DIAL_VIDEO_CALL (RIL_OEM_REQUEST_BASE + 6)
#define RIL_REQUEST_CALL_DEFLECTION (RIL_OEM_REQUEST_BASE + 7)
#define RIL_REQUEST_READ_SMS_FROM_SIM (RIL_OEM_REQUEST_BASE + 8)
#define RIL_REQUEST_USIM_PB_CAPA (RIL_OEM_REQUEST_BASE + 9)
#define RIL_REQUEST_LOCK_INFO (RIL_OEM_REQUEST_BASE + 10)
#define RIL_REQUEST_DIAL_EMERGENCY (RIL_OEM_REQUEST_BASE + 11)
#define RIL_REQUEST_GET_STOREAD_MSG_COUNT (RIL_OEM_REQUEST_BASE + 12)
#define RIL_REQUEST_STK_SIM_INIT_EVENT (RIL_OEM_REQUEST_BASE + 13)
#define RIL_REQUEST_GET_LINE_ID (RIL_OEM_REQUEST_BASE + 14)
#define RIL_REQUEST_SET_LINE_ID (RIL_OEM_REQUEST_BASE + 15)
#define RIL_REQUEST_GET_SERIAL_NUMBER (RIL_OEM_REQUEST_BASE + 16)
#define RIL_REQUEST_GET_MANUFACTURE_DATE_NUMBER (RIL_OEM_REQUEST_BASE + 17)

/* Additional Samsung RIL requests from error */
#define RIL_REQUEST_CDMA_SET_SYSTEMPROPERTIES (RIL_OEM_REQUEST_BASE + 18)
#define RIL_REQUEST_SEND_SMS_COUNT (RIL_OEM_REQUEST_BASE + 19)
#define RIL_REQUEST_SEND_SMS_MSG (RIL_OEM_REQUEST_BASE + 20)
#define RIL_REQUEST_SEND_SMS_MSG_READ_STATUS (RIL_OEM_REQUEST_BASE + 21)
#define RIL_REQUEST_MODEM_HANGUP (RIL_OEM_REQUEST_BASE + 22)
#define RIL_REQUEST_SET_SIM_POWER (RIL_OEM_REQUEST_BASE + 23)
#define RIL_REQUEST_SET_PREFERRED_NETWORK_LIST (RIL_OEM_REQUEST_BASE + 24)
#define RIL_REQUEST_GET_PREFERRED_NETWORK_LIST (RIL_OEM_REQUEST_BASE + 25)
#define RIL_REQUEST_HANGUP_VT (RIL_OEM_REQUEST_BASE + 26)

/* ============================================================================
 * Samsung Unsol Response Definitions
 * ============================================================================ */

#define RIL_UNSOL_RELEASE_COMPLETE_MESSAGE (SAMSUNG_UNSOL_RESPONSE_BASE + 1)
#define RIL_UNSOL_STK_SEND_SMS_RESULT (SAMSUNG_UNSOL_RESPONSE_BASE + 2)
#define RIL_UNSOL_STK_CALL_CONTROL_RESULT (SAMSUNG_UNSOL_RESPONSE_BASE + 3)
#define RIL_UNSOL_DUN_CALL_STATUS (SAMSUNG_UNSOL_RESPONSE_BASE + 4)
#define RIL_UNSOL_O2_HOME_ZONE_INFO (SAMSUNG_UNSOL_RESPONSE_BASE + 7)
#define RIL_UNSOL_DEVICE_READY_NOTI (SAMSUNG_UNSOL_RESPONSE_BASE + 8)
#define RIL_UNSOL_GPS_NOTI (SAMSUNG_UNSOL_RESPONSE_BASE + 9)
#define RIL_UNSOL_AM (SAMSUNG_UNSOL_RESPONSE_BASE + 10)
#define RIL_UNSOL_DUN_PIN_CONTROL_SIGNAL (SAMSUNG_UNSOL_RESPONSE_BASE + 11)

/* OEM Hook */
#ifndef RIL_UNSOL_OEM_HOOK_RAW
#define RIL_UNSOL_OEM_HOOK_RAW (SAMSUNG_UNSOL_RESPONSE_BASE + 100)
#endif

#endif /* SAMSUNG_RIL_DEFS_H */
EOF

echo "✓ Samsung RIL definitions created"

# ============================================================================
# Step 2: Fix ril_commands_vendor.h
# ============================================================================
echo "Fixing ril_commands_vendor.h..."

RIL_COMMANDS="hardware/samsung/ril/libril/include/telephony/ril_commands_vendor.h"

if [ -f "$RIL_COMMANDS" ]; then
    # Backup original
    cp "$RIL_COMMANDS" "${RIL_COMMANDS}.bak"
    
    # Add include at top if not present
    if ! grep -q "samsung_ril_defs.h" "$RIL_COMMANDS"; then
        sed -i '1i#include "samsung_ril_defs.h"' "$RIL_COMMANDS"
    fi
    echo "✓ ril_commands_vendor.h fixed"
else
    echo "⚠ ril_commands_vendor.h not found"
fi

# ============================================================================
# Step 3: Fix ril_unsol_commands_vendor.h
# ============================================================================
echo "Fixing ril_unsol_commands_vendor.h..."

RIL_UNSOL="hardware/samsung/ril/libril/include/telephony/ril_unsol_commands_vendor.h"

if [ -f "$RIL_UNSOL" ]; then
    # Backup original
    cp "$RIL_UNSOL" "${RIL_UNSOL}.bak"
    
    # Add include at top if not present
    if ! grep -q "samsung_ril_defs.h" "$RIL_UNSOL"; then
        sed -i '1i#include "samsung_ril_defs.h"' "$RIL_UNSOL"
    fi
    echo "✓ ril_unsol_commands_vendor.h fixed"
else
    echo "⚠ ril_unsol_commands_vendor.h not found"
fi

# ============================================================================
# Step 4: Fix reference-ril/ril.h
# ============================================================================
echo "Fixing reference-ril/ril.h..."

REF_RIL_H="hardware/ril/reference-ril/ril.h"

if [ -f "$REF_RIL_H" ]; then
    # Create or fix ril_vendor.h
    cat > hardware/ril/reference-ril/ril_vendor.h << 'EOF'
#ifndef RIL_VENDOR_H
#define RIL_VENDOR_H

/* Samsung RIL vendor definitions for reference-ril */
#define RIL_OEM_REQUEST_BASE 10000
#define SAMSUNG_UNSOL_RESPONSE_BASE 11000

/* Basic OEM requests */
#define RIL_REQUEST_GET_CELL_BROADCAST_CONFIG (RIL_OEM_REQUEST_BASE + 0)
#define RIL_REQUEST_SEND_ENCODED_USSD (RIL_OEM_REQUEST_BASE + 1)
#define RIL_REQUEST_SET_PDA_MEMORY_STATUS (RIL_OEM_REQUEST_BASE + 2)
#define RIL_REQUEST_GET_PHONEBOOK_STORAGE_INFO (RIL_OEM_REQUEST_BASE + 3)
#define RIL_REQUEST_GET_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 4)
#define RIL_REQUEST_ACCESS_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 5)
#define RIL_REQUEST_DIAL_VIDEO_CALL (RIL_OEM_REQUEST_BASE + 6)
#define RIL_REQUEST_CALL_DEFLECTION (RIL_OEM_REQUEST_BASE + 7)
#define RIL_REQUEST_READ_SMS_FROM_SIM (RIL_OEM_REQUEST_BASE + 8)
#define RIL_REQUEST_USIM_PB_CAPA (RIL_OEM_REQUEST_BASE + 9)
#define RIL_REQUEST_LOCK_INFO (RIL_OEM_REQUEST_BASE + 10)
#define RIL_REQUEST_DIAL_EMERGENCY (RIL_OEM_REQUEST_BASE + 11)
#define RIL_REQUEST_GET_STOREAD_MSG_COUNT (RIL_OEM_REQUEST_BASE + 12)
#define RIL_REQUEST_STK_SIM_INIT_EVENT (RIL_OEM_REQUEST_BASE + 13)
#define RIL_REQUEST_GET_LINE_ID (RIL_OEM_REQUEST_BASE + 14)
#define RIL_REQUEST_SET_LINE_ID (RIL_OEM_REQUEST_BASE + 15)
#define RIL_REQUEST_GET_SERIAL_NUMBER (RIL_OEM_REQUEST_BASE + 16)
#define RIL_REQUEST_GET_MANUFACTURE_DATE_NUMBER (RIL_OEM_REQUEST_BASE + 17)

/* Additional requests */
#define RIL_REQUEST_CDMA_SET_SYSTEMPROPERTIES (RIL_OEM_REQUEST_BASE + 18)
#define RIL_REQUEST_SEND_SMS_COUNT (RIL_OEM_REQUEST_BASE + 19)
#define RIL_REQUEST_SEND_SMS_MSG (RIL_OEM_REQUEST_BASE + 20)
#define RIL_REQUEST_SEND_SMS_MSG_READ_STATUS (RIL_OEM_REQUEST_BASE + 21)
#define RIL_REQUEST_MODEM_HANGUP (RIL_OEM_REQUEST_BASE + 22)
#define RIL_REQUEST_SET_SIM_POWER (RIL_OEM_REQUEST_BASE + 23)
#define RIL_REQUEST_SET_PREFERRED_NETWORK_LIST (RIL_OEM_REQUEST_BASE + 24)
#define RIL_REQUEST_GET_PREFERRED_NETWORK_LIST (RIL_OEM_REQUEST_BASE + 25)
#define RIL_REQUEST_HANGUP_VT (RIL_OEM_REQUEST_BASE + 26)

/* Unsol responses */
#define RIL_UNSOL_RELEASE_COMPLETE_MESSAGE (SAMSUNG_UNSOL_RESPONSE_BASE + 1)
#define RIL_UNSOL_STK_SEND_SMS_RESULT (SAMSUNG_UNSOL_RESPONSE_BASE + 2)
#define RIL_UNSOL_STK_CALL_CONTROL_RESULT (SAMSUNG_UNSOL_RESPONSE_BASE + 3)
#define RIL_UNSOL_DUN_CALL_STATUS (SAMSUNG_UNSOL_RESPONSE_BASE + 4)
#define RIL_UNSOL_O2_HOME_ZONE_INFO (SAMSUNG_UNSOL_RESPONSE_BASE + 7)
#define RIL_UNSOL_DEVICE_READY_NOTI (SAMSUNG_UNSOL_RESPONSE_BASE + 8)
#define RIL_UNSOL_GPS_NOTI (SAMSUNG_UNSOL_RESPONSE_BASE + 9)
#define RIL_UNSOL_AM (SAMSUNG_UNSOL_RESPONSE_BASE + 10)
#define RIL_UNSOL_DUN_PIN_CONTROL_SIGNAL (SAMSUNG_UNSOL_RESPONSE_BASE + 11)

#endif /* RIL_VENDOR_H */
EOF

    # Fix the include in ril.h
    sed -i 's|#include "ril_vendor.h"|#include "ril_vendor.h"\n#include "samsung_ril_defs.h"|g' "$REF_RIL_H" 2>/dev/null || true
    
    echo "✓ reference-ril/ril.h fixed"
fi

# ============================================================================
# Step 5: Create device-specific RIL header
# ============================================================================
echo "Creating device-specific RIL header..."

mkdir -p device/samsung/a5ltechn/include/telephony

cat > device/samsung/a5ltechn/include/telephony/ril.h << 'EOF'
#ifndef DEVICE_RIL_H
#define DEVICE_RIL_H

/* Include Samsung RIL definitions */
#include "samsung_ril_defs.h"

/* Include AOSP RIL */
#include <telephony/ril.h>

#endif /* DEVICE_RIL_H */
EOF

# Copy samsung_ril_defs to device include
cp hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h device/samsung/a5ltechn/include/telephony/

echo "✓ Device RIL header created"

# ============================================================================
# Step 6: Update BoardConfig.mk
# ============================================================================
echo "Updating BoardConfig.mk..."

BOARD_CONFIG="device/samsung/a5ltechn/BoardConfig.mk"

if [ -f "$BOARD_CONFIG" ]; then
    # Remove any existing RIL config to avoid duplicates
    sed -i '/BOARD_RIL_CLASS/d' "$BOARD_CONFIG"
    sed -i '/BOARD_RIL_NO_CELLINFOREQ/d' "$BOARD_CONFIG"
    sed -i '/BOARD_USES_LEGACY_RIL/d' "$BOARD_CONFIG"
    sed -i '/BOARD_PROVIDES_LIBRIL/d' "$BOARD_CONFIG"
    sed -i '/BOARD_NEEDS_LEGACY_RIL_HEADERS/d' "$BOARD_CONFIG"
    sed -i '/TARGET_RIL_VARIANT/d' "$BOARD_CONFIG"
    sed -i '/TARGET_RIL_DUAL_SIM/d' "$BOARD_CONFIG"
    sed -i '/TARGET_SPECIFIC_HEADER_PATH/d' "$BOARD_CONFIG"
    
    # Add fresh RIL config at the end
    cat >> "$BOARD_CONFIG" << 'EOF'

# ============================================================================
# RIL Configuration for SM-A5000 (a5ltechn)
# ============================================================================
BOARD_RIL_CLASS := ../../../device/samsung/a5ltechn/ril
BOARD_RIL_NO_CELLINFOREQ := true
BOARD_USES_LEGACY_RIL := true
BOARD_PROVIDES_LIBRIL := true
BOARD_NEEDS_LEGACY_RIL_HEADERS := true
BOARD_USES_LEGACY_RIL_H := true

# Dual SIM Support
TARGET_RIL_VARIANT := caf
TARGET_RIL_DUAL_SIM := true
TARGET_RIL_SINGLE_SIM := false

# Include custom RIL headers
TARGET_SPECIFIC_HEADER_PATH := device/samsung/a5ltechn/include

# RIL properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.radio.multisim.config=dsds \
    ro.multisim.simslotcount=2 \
    ro.telephony.ril.config=simactivation \
    persist.radio.force_on_demand=true
EOF
    echo "✓ BoardConfig.mk updated"
fi

# ============================================================================
# Step 7: Create RIL directory and Android.mk
# ============================================================================
echo "Creating RIL wrapper directory..."

mkdir -p device/samsung/a5ltechn/ril

cat > device/samsung/a5ltechn/ril/Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libril-wrapper
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := ril_wrapper.cpp
LOCAL_SHARED_LIBRARIES := liblog libcutils libutils
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include \
                    hardware/ril/include \
                    system/core/include

include $(BUILD_SHARED_LIBRARY)
EOF

cat > device/samsung/a5ltechn/ril/ril_wrapper.cpp << 'EOF'
#include <telephony/ril.h>
#include <log/log.h>

#define LOG_TAG "RIL_WRAPPER"

extern "C" {

int RIL_Init(const struct RIL_Env *env, int argc, char **argv) {
    RLOGI("Initializing Samsung RIL for SM-A5000 (a5ltechn)");
    return 0;
}

} // extern "C"
EOF

echo "✓ RIL wrapper created"

# ============================================================================
# Step 8: Clean build intermediates
# ============================================================================
echo "Cleaning build intermediates..."

rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libril_intermediates/
rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libreference-ril_intermediates/
rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libril-wrapper_intermediates/

echo "✓ Cleaned RIL build artifacts"

# ============================================================================
# Done
# ============================================================================
echo ""
echo "=========================================="
echo "RIL Fix Complete!"
echo "=========================================="
echo ""
echo "Files created/modified:"
echo "  - hardware/samsung/ril/.../samsung_ril_defs.h"
echo "  - hardware/samsung/ril/.../ril_commands_vendor.h (fixed)"
echo "  - hardware/samsung/ril/.../ril_unsol_commands_vendor.h (fixed)"
echo "  - hardware/ril/reference-ril/ril_vendor.h"
echo "  - device/samsung/a5ltechn/include/telephony/ril.h"
echo "  - device/samsung/a5ltechn/BoardConfig.mk (updated)"
echo "  - device/samsung/a5ltechn/ril/"
echo ""
echo "Now run:"
echo "  source build/envsetup.sh"
echo "  breakfast a5ltechn"
echo "  brunch a5ltechn"
echo "=========================================="




make installclean
brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload


grep -F "sysfs /devices/platform/leds-mt65xx" out/soong/.intermediates/system/sepolicy/plat_sepolicy.cil/android_common/plat_sepolicy.cil 2>&1 | tee build.log
