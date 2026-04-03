#!/bin/bash
# fix_samsung_ril.sh — Auto-fix Samsung RIL build errors for a5ltechn
# Run from the root of your Android source tree:
#   bash fix_samsung_ril.sh

set -e
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "${BOLD}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

# ── Sanity check ────────────────────────────────────────────────────────────
[[ -f "build/envsetup.sh" ]] || die "Run this from the root of your Android source tree."

# ════════════════════════════════════════════════════════════════════════════
# FIX 1 — samsung_ril_defs.h missing from reference-ril include path
# ════════════════════════════════════════════════════════════════════════════
info "Searching for samsung_ril_defs.h ..."
DEFS_LOCATIONS=$(find device/ hardware/ -name "samsung_ril_defs.h" 2>/dev/null)

if [[ -z "$DEFS_LOCATIONS" ]]; then
    warn "samsung_ril_defs.h not found anywhere in device/ or hardware/."
    warn "The repo that provides it may not be synced."
    warn "Check your .repo/local_manifests for a missing Samsung RIL definitions repo."
    warn "Skipping Fix 1 — you must sync the missing repo first."
else
    DEFS_DIR=$(echo "$DEFS_LOCATIONS" | head -1 | xargs dirname)
    info "Found samsung_ril_defs.h in: $DEFS_DIR"

    REFRIL_MK="hardware/ril/reference-ril/Android.mk"
    if [[ ! -f "$REFRIL_MK" ]]; then
        warn "$REFRIL_MK not found — skipping Fix 1."
    else
        if grep -q "samsung_ril_defs" "$REFRIL_MK" 2>/dev/null; then
            success "Fix 1 already applied (include path already present in $REFRIL_MK)."
        else
            info "Patching $REFRIL_MK ..."
            # Insert after the first LOCAL_C_INCLUDES line, or before LOCAL_SRC_FILES
            if grep -q "LOCAL_C_INCLUDES" "$REFRIL_MK"; then
                sed -i "/LOCAL_C_INCLUDES/a LOCAL_C_INCLUDES += $DEFS_DIR" "$REFRIL_MK"
            else
                sed -i "/LOCAL_SRC_FILES/i LOCAL_C_INCLUDES += $DEFS_DIR\n" "$REFRIL_MK"
            fi
            success "Fix 1 applied: added $DEFS_DIR to $REFRIL_MK"
        fi
    fi
fi

# ════════════════════════════════════════════════════════════════════════════
# FIX 2 — RIL_UNSOL_* identifiers undeclared in hardware/samsung/ril/libril
# ════════════════════════════════════════════════════════════════════════════
info "Searching for the ril.h that defines RIL_UNSOL_DATA_SUSPEND_RESUME ..."

DEFINING_HEADERS=$(grep -rl "RIL_UNSOL_DATA_SUSPEND_RESUME" device/ hardware/ \
    --include="*.h" 2>/dev/null | grep -v "commands_vendor")

if [[ -z "$DEFINING_HEADERS" ]]; then
    die "Cannot find any header defining RIL_UNSOL_DATA_SUSPEND_RESUME. Tree may be incomplete."
fi

# Prefer device/samsung/a5-common if present
DEFINING_HDR=$(echo "$DEFINING_HEADERS" | grep "a5-common" | head -1)
[[ -z "$DEFINING_HDR" ]] && DEFINING_HDR=$(echo "$DEFINING_HEADERS" | head -1)
DEFINING_DIR=$(dirname "$DEFINING_HDR" | sed 's|/telephony$||')
info "Found defining header: $DEFINING_HDR"
info "Will add include dir: $DEFINING_DIR"

# ── 2a. Patch Android.mk ────────────────────────────────────────────────────
LIBRIL_MK="hardware/samsung/ril/libril/Android.mk"
if [[ -f "$LIBRIL_MK" ]]; then
    if grep -q "$DEFINING_DIR" "$LIBRIL_MK" 2>/dev/null; then
        success "Fix 2a already applied (include path already in $LIBRIL_MK)."
    else
        info "Patching $LIBRIL_MK ..."
        if grep -q "LOCAL_C_INCLUDES" "$LIBRIL_MK"; then
            sed -i "/LOCAL_C_INCLUDES/a LOCAL_C_INCLUDES += $DEFINING_DIR" "$LIBRIL_MK"
        else
            sed -i "/LOCAL_SRC_FILES/i LOCAL_C_INCLUDES += $DEFINING_DIR\n" "$LIBRIL_MK"
        fi
        success "Fix 2a applied: added $DEFINING_DIR to $LIBRIL_MK"
    fi
else
    warn "$LIBRIL_MK not found — skipping Android.mk patch."
fi

# ── 2b. Patch Android.bp (if present) ───────────────────────────────────────
LIBRIL_BP="hardware/samsung/ril/libril/Android.bp"
if [[ -f "$LIBRIL_BP" ]]; then
    if grep -q "$DEFINING_DIR" "$LIBRIL_BP" 2>/dev/null; then
        success "Fix 2b already applied (include path already in $LIBRIL_BP)."
    else
        info "Patching $LIBRIL_BP ..."
        # Insert into the first include_dirs block, or create one before the first }
        if grep -q "include_dirs:" "$LIBRIL_BP"; then
            sed -i "/include_dirs:/a \        \"$DEFINING_DIR\"," "$LIBRIL_BP"
        else
            # Add include_dirs block before the closing brace of the first module
            awk -v dir="$DEFINING_DIR" '
                !inserted && /^}/ {
                    print "    include_dirs: ["
                    print "        \"" dir "\","
                    print "    ],"
                    inserted=1
                }
                { print }
            ' "$LIBRIL_BP" > "${LIBRIL_BP}.tmp" && mv "${LIBRIL_BP}.tmp" "$LIBRIL_BP"
        fi
        success "Fix 2b applied: added $DEFINING_DIR to $LIBRIL_BP"
    fi
fi

# ── 2c. Check include order in ril.cpp ──────────────────────────────────────
RILCPP="hardware/samsung/ril/libril/ril.cpp"
if [[ -f "$RILCPP" ]]; then
    info "Checking include order in $RILCPP ..."

    RIL_H_LINE=$(grep -n '#include.*[<"]telephony/ril\.h[>"]' "$RILCPP" | head -1 | cut -d: -f1)
    CMD_V_LINE=$(grep -n '#include.*ril_unsol_commands_vendor\.h' "$RILCPP" | head -1 | cut -d: -f1)

    if [[ -z "$RIL_H_LINE" ]]; then
        warn "telephony/ril.h is not included in $RILCPP at all."
        info "Inserting #include <telephony/ril.h> before ril_unsol_commands_vendor.h ..."
        sed -i 's|#include.*ril_unsol_commands_vendor\.h|#include <telephony/ril.h>\n#include "telephony/ril_unsol_commands_vendor.h"|' "$RILCPP"
        success "Fix 2c applied: inserted ril.h include before commands_vendor include."
    elif [[ -n "$CMD_V_LINE" && "$RIL_H_LINE" -gt "$CMD_V_LINE" ]]; then
        warn "Include order is wrong: ril_unsol_commands_vendor.h (line $CMD_V_LINE) comes before telephony/ril.h (line $RIL_H_LINE)."
        info "Reordering includes ..."
        # Remove the ril.h include line, then re-insert it just before the commands_vendor include
        RIL_H_INCLUDE=$(grep '#include.*[<"]telephony/ril\.h[>"]' "$RILCPP" | head -1)
        sed -i "/$RIL_H_INCLUDE/d" "$RILCPP"
        sed -i "s|#include.*ril_unsol_commands_vendor\.h|$RIL_H_INCLUDE\n#include \"telephony/ril_unsol_commands_vendor.h\"|" "$RILCPP"
        success "Fix 2c applied: ril.h now precedes ril_unsol_commands_vendor.h."
    else
        success "Include order in $RILCPP looks correct (ril.h line $RIL_H_LINE, commands_vendor line $CMD_V_LINE)."
    fi
else
    warn "$RILCPP not found — skipping include order check."
fi

# ════════════════════════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD} Done. Retry your build:${NC}"
echo -e "   source build/envsetup.sh"
echo -e "   breakfast a5ltechn        # or your lunch target"
echo -e "   mka bacon 2>&1 | tee build.log"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
