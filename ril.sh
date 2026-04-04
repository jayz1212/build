#!/bin/bash

# ============================================================================
# Complete RIL Disable Script for SM-A5000 (a5ltechn)
# This completely disables RIL/cellular functionality for Wi-Fi only use
# ============================================================================

echo "=========================================="
echo "Disabling RIL for SM-A5000 (a5ltechn)"
echo "Wi-Fi Only Mode"
echo "=========================================="

# ============================================================================
# Step 1: Modify BoardConfig.mk to disable RIL
# ============================================================================
echo "Step 1: Modifying BoardConfig.mk..."

BOARD_CONFIG="device/samsung/a5ltechn/BoardConfig.mk"

if [ -f "$BOARD_CONFIG" ]; then
    # Remove any existing RIL config
    sed -i '/BOARD_RIL_CLASS/d' "$BOARD_CONFIG"
    sed -i '/BOARD_RIL_NO_CELLINFOREQ/d' "$BOARD_CONFIG"
    sed -i '/BOARD_USES_LEGACY_RIL/d' "$BOARD_CONFIG"
    sed -i '/BOARD_PROVIDES_LIBRIL/d' "$BOARD_CONFIG"
    sed -i '/BOARD_NEEDS_LEGACY_RIL_HEADERS/d' "$BOARD_CONFIG"
    sed -i '/TARGET_RIL_VARIANT/d' "$BOARD_CONFIG"
    sed -i '/TARGET_RIL_DUAL_SIM/d' "$BOARD_CONFIG"
    
    # Add RIL disable flags
    cat >> "$BOARD_CONFIG" << 'EOF'

# ============================================================================
# RIL Disabled - Wi-Fi Only Mode
# ============================================================================
BOARD_RIL_DISABLED := true
BUILD_WITHOUT_RIL := true
TARGET_NO_RIL := true
BOARD_PROVIDES_RILD := false
BOARD_NEEDS_LIBRIL := false
BOARD_USES_RILD := false
EOF
    echo "✓ BoardConfig.mk modified (RIL disabled)"
else
    echo "⚠ BoardConfig.mk not found, creating..."
    cat > "$BOARD_CONFIG" << 'EOF'
# BoardConfig for SM-A5000 (a5ltechn) - Wi-Fi Only
TARGET_NO_RIL := true
BOARD_RIL_DISABLED := true
BUILD_WITHOUT_RIL := true
BOARD_PROVIDES_RILD := false
EOF
fi

# ============================================================================
# Step 2: Modify system.prop to disable RIL
# ============================================================================
echo "Step 2: Modifying system.prop..."

SYSTEM_PROP="device/samsung/a5ltechn/system.prop"

if [ -f "$SYSTEM_PROP" ]; then
    # Remove any RIL properties
    sed -i '/rild/d' "$SYSTEM_PROP"
    sed -i '/telephony/d' "$SYSTEM_PROP"
    sed -i '/ril/d' "$SYSTEM_PROP"
    sed -i '/multisim/d' "$SYSTEM_PROP"
    
    # Add disable flags
    cat >> "$SYSTEM_PROP" << 'EOF'

# RIL Disabled - Wi-Fi Only Mode
rild.libpath=/system/lib/libreference-ril.so
rild.libargs=-d /dev/ttyS0
ro.telephony.disable-call=true
ro.telephony.disable-sms=true
ro.radio.noril=true
persist.radio.noril=true
ro.config.disable_cellular=true
EOF
    echo "✓ system.prop modified"
else
    echo "⚠ system.prop not found, creating..."
    cat > "$SYSTEM_PROP" << 'EOF'
# RIL Disabled - Wi-Fi Only Mode
rild.libpath=/system/lib/libreference-ril.so
ro.telephony.disable-call=true
ro.telephony.disable-sms=true
ro.radio.noril=true
persist.radio.noril=true
EOF
fi

# ============================================================================
# Step 3: Create empty RIL stub headers to bypass compilation
# ============================================================================
echo "Step 3: Creating RIL stub headers..."

# Create directory
mkdir -p device/samsung/a5ltechn/include/telephony

# Create stub ril.h
cat > device/samsung/a5ltechn/include/telephony/ril.h << 'EOF'
#ifndef STUB_RIL_H
#define STUB_RIL_H

/* Stub RIL header - RIL completely disabled */
#define RIL_DISABLED 1

/* Empty definitions to satisfy compilation */
typedef void* RIL_Token;
typedef int RIL_Errno;
typedef int RIL_RadioState;

/* Stub functions */
static inline void RIL_register(const void* callbacks) { }
static inline void RIL_onRequestComplete(RIL_Token t, RIL_Errno e, void* response, size_t len) { }
static inline void RIL_onUnsolicitedResponse(int unsolResponse, void* data, size_t datalen) { }

#endif
EOF

echo "✓ Stub RIL headers created"

# ============================================================================
# Step 4: Override hardware/samsung/ril with stub
# ============================================================================
echo "Step 4: Creating RIL stub override..."

# Create Android.mk that does nothing for RIL
mkdir -p device/samsung/a5ltechn/ril_stub

cat > device/samsung/a5ltechn/ril_stub/Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)

# Empty RIL stub - do nothing
include $(CLEAR_VARS)
LOCAL_MODULE := libril-stub
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := ril_stub.cpp
LOCAL_SHARED_LIBRARIES := liblog
include $(BUILD_SHARED_LIBRARY)
EOF

cat > device/samsung/a5ltechn/ril_stub/ril_stub.cpp << 'EOF'
#include <log/log.h>

#define LOG_TAG "RIL_STUB"

extern "C" {

int RIL_Init(const void* env, int argc, char** argv) {
    RLOGI("RIL STUB: RIL is disabled (Wi-Fi only mode)");
    return 0;
}

void RIL_register(const void* callbacks) {
    RLOGI("RIL STUB: RIL registration ignored");
}

} // extern "C"
EOF

echo "✓ RIL stub created"

# ============================================================================
# Step 5: Remove RIL from PRODUCT_PACKAGES
# ============================================================================
echo "Step 5: Removing RIL from build packages..."

# Modify lineage_a5ltechn.mk to exclude RIL
LINEAGE_MK="device/samsung/a5ltechn/lineage_a5ltechn.mk"

if [ -f "$LINEAGE_MK" ]; then
    # Add RIL exclusion
    cat >> "$LINEAGE_MK" << 'EOF'

# RIL Disabled - Exclude RIL packages
PRODUCT_PACKAGES := $(filter-out rild,\
    $(PRODUCT_PACKAGES))
PRODUCT_PACKAGES := $(filter-out libril,\
    $(PRODUCT_PACKAGES))
PRODUCT_PACKAGES := $(filter-out libreference-ril,\
    $(PRODUCT_PACKAGES))
PRODUCT_PACKAGES := $(filter-out libril-wrapper,\
    $(PRODUCT_PACKAGES))
EOF
    echo "✓ lineage_a5ltechn.mk modified"
fi

# ============================================================================
# Step 6: Clean build intermediates
# ============================================================================
echo "Step 6: Cleaning build intermediates..."

rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libril_intermediates/
rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libreference-ril_intermediates/
rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libril-wrapper_intermediates/
rm -rf out/target/product/a5ltechn/obj/EXECUTABLES/rild_intermediates/

echo "✓ Build intermediates cleaned"

# ============================================================================
# Step 7: Create device.mk override
# ============================================================================
echo "Step 7: Creating device.mk with RIL disabled..."

cat > device/samsung/a5ltechn/device.mk << 'EOF'
# Device.mk for SM-A5000 - RIL Disabled (Wi-Fi Only)

# Disable telephony
PRODUCT_COPY_FILES := \
    device/samsung/a5ltechn/disable_telephony.prop:system/build.prop

# Override telephony packages
PRODUCT_PACKAGES += \
    WifiOnly

# Remove telephony from PRODUCT_PROPERTY_OVERRIDES
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.disable-call=true \
    ro.telephony.disable-sms=true \
    ro.radio.noril=true \
    persist.radio.noril=true \
    ro.config.disable_cellular=true
EOF

echo "✓ device.mk created"

# ============================================================================
# Done
# ============================================================================
echo ""
echo "=========================================="
echo "RIL Successfully Disabled!"
echo "Wi-Fi Only Mode Enabled"
echo "=========================================="
echo ""
echo "The ROM will now build as a Wi-Fi only device."
echo "No cellular functionality will be present."
echo ""
echo "Now run:"
echo "  source build/envsetup.sh"
echo "  breakfast a5ltechn"
echo "  brunch a5ltechn"
echo "=========================================="
