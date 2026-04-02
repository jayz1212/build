#!/bin/bash

# ============================================================================
# Minimal RIL Fix for Samsung SM-A5000 (a5ltechn)
# ============================================================================

echo "Applying RIL fix for a5ltechn..."

# ============================================================================
# Step 1: Create RIL wrapper directory and header
# ============================================================================
mkdir -p device/samsung/a5ltechn/include/telephony

# Create RIL header with Samsung definitions
cat > device/samsung/a5ltechn/include/telephony/ril.h << 'EOF'
#ifndef SAMSUNG_RIL_WRAPPER_H
#define SAMSUNG_RIL_WRAPPER_H

#include <telephony/ril.h>

/* Samsung OEM RIL extensions */
#ifndef RIL_OEM_REQUEST_BASE
#define RIL_OEM_REQUEST_BASE 10000
#endif

#ifndef RIL_REQUEST_GET_CELL_BROADCAST_CONFIG
#define RIL_REQUEST_GET_CELL_BROADCAST_CONFIG (RIL_OEM_REQUEST_BASE + 0)
#endif

#ifndef RIL_REQUEST_SEND_ENCODED_USSD
#define RIL_REQUEST_SEND_ENCODED_USSD (RIL_OEM_REQUEST_BASE + 1)
#endif

#ifndef RIL_REQUEST_SET_PDA_MEMORY_STATUS
#define RIL_REQUEST_SET_PDA_MEMORY_STATUS (RIL_OEM_REQUEST_BASE + 2)
#endif

#ifndef RIL_REQUEST_GET_PHONEBOOK_STORAGE_INFO
#define RIL_REQUEST_GET_PHONEBOOK_STORAGE_INFO (RIL_OEM_REQUEST_BASE + 3)
#endif

#ifndef RIL_REQUEST_GET_PHONEBOOK_ENTRY
#define RIL_REQUEST_GET_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 4)
#endif

#ifndef RIL_REQUEST_ACCESS_PHONEBOOK_ENTRY
#define RIL_REQUEST_ACCESS_PHONEBOOK_ENTRY (RIL_OEM_REQUEST_BASE + 5)
#endif

#ifndef RIL_REQUEST_DIAL_VIDEO_CALL
#define RIL_REQUEST_DIAL_VIDEO_CALL (RIL_OEM_REQUEST_BASE + 6)
#endif

#ifndef RIL_REQUEST_CALL_DEFLECTION
#define RIL_REQUEST_CALL_DEFLECTION (RIL_OEM_REQUEST_BASE + 7)
#endif

#ifndef RIL_REQUEST_READ_SMS_FROM_SIM
#define RIL_REQUEST_READ_SMS_FROM_SIM (RIL_OEM_REQUEST_BASE + 8)
#endif

#ifndef RIL_REQUEST_USIM_PB_CAPA
#define RIL_REQUEST_USIM_PB_CAPA (RIL_OEM_REQUEST_BASE + 9)
#endif

#ifndef RIL_REQUEST_LOCK_INFO
#define RIL_REQUEST_LOCK_INFO (RIL_OEM_REQUEST_BASE + 10)
#endif

#ifndef RIL_REQUEST_DIAL_EMERGENCY
#define RIL_REQUEST_DIAL_EMERGENCY (RIL_OEM_REQUEST_BASE + 11)
#endif

#ifndef RIL_REQUEST_GET_STOREAD_MSG_COUNT
#define RIL_REQUEST_GET_STOREAD_MSG_COUNT (RIL_OEM_REQUEST_BASE + 12)
#endif

#ifndef RIL_REQUEST_STK_SIM_INIT_EVENT
#define RIL_REQUEST_STK_SIM_INIT_EVENT (RIL_OEM_REQUEST_BASE + 13)
#endif

#ifndef RIL_REQUEST_GET_LINE_ID
#define RIL_REQUEST_GET_LINE_ID (RIL_OEM_REQUEST_BASE + 14)
#endif

#ifndef RIL_REQUEST_SET_LINE_ID
#define RIL_REQUEST_SET_LINE_ID (RIL_OEM_REQUEST_BASE + 15)
#endif

#ifndef RIL_REQUEST_GET_SERIAL_NUMBER
#define RIL_REQUEST_GET_SERIAL_NUMBER (RIL_OEM_REQUEST_BASE + 16)
#endif

#ifndef RIL_REQUEST_GET_MANUFACTURE_DATE_NUMBER
#define RIL_REQUEST_GET_MANUFACTURE_DATE_NUMBER (RIL_OEM_REQUEST_BASE + 17)
#endif

#endif
EOF

echo "✓ RIL header created"

# ============================================================================
# Step 2: Add RIL configuration to BoardConfig.mk
# ============================================================================
BOARD_CONFIG="device/samsung/a5ltechn/BoardConfig.mk"

if [ -f "$BOARD_CONFIG" ]; then
    # Check if RIL config already exists
    if ! grep -q "BOARD_RIL_CLASS" "$BOARD_CONFIG"; then
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
EOF
        echo "✓ RIL config added to BoardConfig.mk"
    else
        echo "✓ RIL config already exists in BoardConfig.mk"
    fi
else
    echo "⚠ BoardConfig.mk not found, creating one..."
    
    cat > "$BOARD_CONFIG" << 'EOF'
# BoardConfig for SM-A5000 (a5ltechn)

# RIL Configuration
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
EOF
    echo "✓ BoardConfig.mk created"
fi

# ============================================================================
# Step 3: Add dual SIM properties to system.prop
# ============================================================================
SYSTEM_PROP="device/samsung/a5ltechn/system.prop"

if [ -f "$SYSTEM_PROP" ]; then
    if ! grep -q "persist.radio.multisim.config" "$SYSTEM_PROP"; then
        cat >> "$SYSTEM_PROP" << 'EOF'

# Dual SIM properties
persist.radio.multisim.config=dsds
ro.multisim.simslotcount=2
ro.telephony.ril.config=simactivation
persist.radio.force_on_demand=true
EOF
        echo "✓ Dual SIM properties added to system.prop"
    else
        echo "✓ Dual SIM properties already exist in system.prop"
    fi
else
    echo "⚠ system.prop not found, skipping"
fi

# ============================================================================
# Step 4: Fix the hardware/samsung/ril header
# ============================================================================
if [ -f "hardware/samsung/ril/libril/include/telephony/ril_commands_vendor.h" ]; then
    # Create samsung_ril_defs.h
    cat > hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h << 'EOF'
#ifndef SAMSUNG_RIL_DEFS_H
#define SAMSUNG_RIL_DEFS_H

#ifndef RIL_OEM_REQUEST_BASE
#define RIL_OEM_REQUEST_BASE 10000
#endif

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

#endif
EOF

    # Add include to ril_commands_vendor.h if not already there
    if ! grep -q "samsung_ril_defs.h" hardware/samsung/ril/libril/include/telephony/ril_commands_vendor.h; then
        sed -i '1i#include "samsung_ril_defs.h"' hardware/samsung/ril/libril/include/telephony/ril_commands_vendor.h
    fi
    
    echo "✓ hardware/samsung/ril headers fixed"
else
    echo "⚠ hardware/samsung/ril not found, skipping"
fi

# ============================================================================
# Step 5: Clean RIL build intermediates
# ============================================================================
rm -rf out/target/product/a5ltechn/obj/SHARED_LIBRARIES/libril_intermediates/
echo "✓ RIL build intermediates cleaned"

# ============================================================================
# Done
# ============================================================================
echo ""
echo "=========================================="
echo "RIL fix applied successfully!"
echo "=========================================="
echo ""
echo "Now run:"
echo "  source build/envsetup.sh"
echo "  breakfast a5ltechn"
echo "  brunch a5ltechn"
echo "=========================================="
