#!/bin/bash
# fix_samsung_ril.sh — Fix all Samsung RIL build errors for a5ltechn / LineageOS 17.1
# Run from the root of your Android source tree:
#   bash fix_samsung_ril.sh
#
# Problems solved:
#   1. hardware/ril/reference-ril: fatal error: 'samsung_ril_defs.h' file not found
#   2. hardware/samsung/ril/libril: RIL_UNSOL_* / RIL_REQUEST_* macro redefined
#      (caused by device/samsung/a5-common/include clashing with libril's own headers)
#   3. hardware/samsung/ril/libril: RIL_UNSOL_* undeclared (original error, now fixed properly)

set -euo pipefail
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
header()  { echo -e "\n${BOLD}━━━  $*  ━━━${NC}"; }

# ── Sanity check ─────────────────────────────────────────────────────────────
[[ -f "build/envsetup.sh" ]] || die "Run this from the root of your Android source tree."

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Remove every line matching a pattern from a file (idempotent)
remove_line() {
    local file="$1" pattern="$2"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        sed -i "\|$pattern|d" "$file"
        info "Removed '$pattern' from $file"
    else
        info "Pattern not present (nothing to remove): '$pattern' in $file"
    fi
}

# Add a LOCAL_C_INCLUDES line if not already present
add_c_include_mk() {
    local file="$1" path="$2"
    if grep -qF "$path" "$file" 2>/dev/null; then
        success "Include already present in $file: $path"
        return
    fi
    if grep -q "LOCAL_C_INCLUDES" "$file"; then
        sed -i "/LOCAL_C_INCLUDES/a LOCAL_C_INCLUDES += $path" "$file"
    else
        sed -i "/LOCAL_SRC_FILES/i LOCAL_C_INCLUDES += $path\n" "$file"
    fi
    success "Added include to $file: $path"
}

# ═════════════════════════════════════════════════════════════════════════════
# FIX 1 — hardware/ril/reference-ril: samsung_ril_defs.h not found
#
# reference-ril/ril.h does:  #include "samsung_ril_defs.h"  (bare filename)
# The file lives at:  hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h
# So we add that telephony/ dir to reference-ril's include path.
# ═════════════════════════════════════════════════════════════════════════════
header "FIX 1 — reference-ril: samsung_ril_defs.h not found"

REFRIL_MK="hardware/ril/reference-ril/Android.mk"
[[ -f "$REFRIL_MK" ]] || die "$REFRIL_MK not found. Are you in the right directory?"

# Confirmed location from:  find . -name samsung_ril_defs.h
SAMSUNG_DEFS_TELEPHONY_DIR="hardware/samsung/ril/libril/include/telephony"

if [[ ! -f "$SAMSUNG_DEFS_TELEPHONY_DIR/samsung_ril_defs.h" ]]; then
    FOUND=$(find hardware/ device/ -name "samsung_ril_defs.h" 2>/dev/null | head -1)
    [[ -n "$FOUND" ]] || die "samsung_ril_defs.h not found anywhere. Sync the Samsung RIL repo."
    SAMSUNG_DEFS_TELEPHONY_DIR=$(dirname "$FOUND")
    warn "Using dynamically found path: $SAMSUNG_DEFS_TELEPHONY_DIR"
fi

info "samsung_ril_defs.h found at: $SAMSUNG_DEFS_TELEPHONY_DIR"
add_c_include_mk "$REFRIL_MK" "$SAMSUNG_DEFS_TELEPHONY_DIR"

# ═════════════════════════════════════════════════════════════════════════════
# FIX 2 — hardware/samsung/ril/libril: macro redefinition + undeclared identifiers
#
# Root cause: two competing definitions of the Samsung RIL macros:
#   A) hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h
#      → defines them as (BASE + offset) expressions  ← libril's own copy
#   B) device/samsung/a5-common/include/telephony/ril.h
#      → defines them as hardcoded numbers             ← device tree copy
#
# libril's ril_commands_vendor.h includes samsung_ril_defs.h from (A).
# If device/samsung/a5-common/include is ALSO on the path, ril.h from (B)
# is pulled in first, defines everything, then (A) redefines → -Wmacro-redefined.
#
# Fix:
#   • Remove device/samsung/a5-common/include from libril's path (clash source)
#   • Add hardware/samsung/ril/libril/include so libril's own headers resolve
# ═════════════════════════════════════════════════════════════════════════════
header "FIX 2 — libril: macro redefinition / undeclared identifiers"

LIBRIL_MK="hardware/samsung/ril/libril/Android.mk"
[[ -f "$LIBRIL_MK" ]] || die "$LIBRIL_MK not found."

LIBRIL_INCLUDE_DIR="hardware/samsung/ril/libril/include"
A5_COMMON_INCLUDE="device/samsung/a5-common/include"

# 2a — Remove clashing a5-common include (may have been added by a previous run)
header "FIX 2a — Remove clashing a5-common include from libril"
remove_line "$LIBRIL_MK" "LOCAL_C_INCLUDES.*$A5_COMMON_INCLUDE"
success "Ensured $A5_COMMON_INCLUDE is NOT in $LIBRIL_MK"

# 2b — Add libril's own include dir so its internal headers resolve correctly
header "FIX 2b — Add libril's own include dir"
add_c_include_mk "$LIBRIL_MK" "$LIBRIL_INCLUDE_DIR"

# 2c — Also patch Android.bp if one exists alongside the .mk
LIBRIL_BP="hardware/samsung/ril/libril/Android.bp"
if [[ -f "$LIBRIL_BP" ]]; then
    header "FIX 2c — Patch Android.bp"

    if grep -q "$A5_COMMON_INCLUDE" "$LIBRIL_BP"; then
        sed -i "\|$A5_COMMON_INCLUDE|d" "$LIBRIL_BP"
        info "Removed $A5_COMMON_INCLUDE from $LIBRIL_BP"
    fi

    if grep -qF "$LIBRIL_INCLUDE_DIR" "$LIBRIL_BP"; then
        success "Include already present in $LIBRIL_BP: $LIBRIL_INCLUDE_DIR"
    else
        if grep -q "include_dirs:" "$LIBRIL_BP"; then
            sed -i "/include_dirs:/a \        \"$LIBRIL_INCLUDE_DIR\"," "$LIBRIL_BP"
        else
            awk -v dir="$LIBRIL_INCLUDE_DIR" '
                !inserted && /^}/ {
                    print "    include_dirs: ["
                    print "        \"" dir "\","
                    print "    ],"
                    inserted=1
                }
                { print }
            ' "$LIBRIL_BP" > "${LIBRIL_BP}.tmp" && mv "${LIBRIL_BP}.tmp" "$LIBRIL_BP"
        fi
        success "Added include to $LIBRIL_BP: $LIBRIL_INCLUDE_DIR"
    fi
else
    info "No Android.bp found for libril — skipping."
fi

# ═════════════════════════════════════════════════════════════════════════════
# FIX 3 — Verify/fix include order in hardware/samsung/ril/libril/ril.cpp
#
# telephony/ril.h must appear BEFORE ril_commands_vendor.h and
# ril_unsol_commands_vendor.h so that the enum/macro definitions are
# visible when the vendor command tables are parsed.
# ═════════════════════════════════════════════════════════════════════════════
header "FIX 3 — Verify include order in ril.cpp"

RILCPP="hardware/samsung/ril/libril/ril.cpp"
if [[ ! -f "$RILCPP" ]]; then
    warn "$RILCPP not found — skipping."
else
    RIL_H_LINE=$(grep -n '#include.*[<"]telephony/ril\.h[>"]' "$RILCPP" | head -1 | cut -d: -f1)
    CMD_V_LINE=$(grep -n '#include.*ril_commands_vendor\.h' "$RILCPP" | head -1 | cut -d: -f1)
    UNSOL_V_LINE=$(grep -n '#include.*ril_unsol_commands_vendor\.h' "$RILCPP" | head -1 | cut -d: -f1)

    # Find the earliest vendor commands include
    FIRST_VENDOR=""
    if [[ -n "$CMD_V_LINE" && -n "$UNSOL_V_LINE" ]]; then
        [[ "$CMD_V_LINE" -lt "$UNSOL_V_LINE" ]] && FIRST_VENDOR=$CMD_V_LINE || FIRST_VENDOR=$UNSOL_V_LINE
    elif [[ -n "$CMD_V_LINE" ]]; then
        FIRST_VENDOR=$CMD_V_LINE
    elif [[ -n "$UNSOL_V_LINE" ]]; then
        FIRST_VENDOR=$UNSOL_V_LINE
    fi

    if [[ -z "$RIL_H_LINE" ]]; then
        warn "telephony/ril.h not included in $RILCPP."
        if [[ -n "$FIRST_VENDOR" ]]; then
            info "Inserting #include <telephony/ril.h> before line $FIRST_VENDOR..."
            sed -i "${FIRST_VENDOR}i #include <telephony/ril.h>" "$RILCPP"
            success "Inserted #include <telephony/ril.h> before vendor command headers."
        else
            warn "No vendor command headers found either — manual inspection needed."
        fi
    elif [[ -n "$FIRST_VENDOR" && "$RIL_H_LINE" -gt "$FIRST_VENDOR" ]]; then
        warn "Wrong order: vendor commands at line $FIRST_VENDOR, ril.h at line $RIL_H_LINE. Fixing..."
        RIL_H_INCLUDE=$(sed -n "${RIL_H_LINE}p" "$RILCPP")
        sed -i "${RIL_H_LINE}d" "$RILCPP"
        sed -i "${FIRST_VENDOR}i $RIL_H_INCLUDE" "$RILCPP"
        success "Reordered: ril.h now precedes vendor command headers."
    else
        success "Include order correct in $RILCPP (ril.h: line $RIL_H_LINE, first vendor: line ${FIRST_VENDOR:-n/a})."
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD} All fixes applied. Summary:${NC}"
echo -e ""
echo -e "  ${GREEN}Fix 1${NC}   Added ${SAMSUNG_DEFS_TELEPHONY_DIR}"
echo -e "          → hardware/ril/reference-ril/Android.mk"
echo -e "          Resolves: fatal error: 'samsung_ril_defs.h' file not found"
echo -e ""
echo -e "  ${GREEN}Fix 2a${NC}  Removed device/samsung/a5-common/include"
echo -e "          → hardware/samsung/ril/libril/Android.mk"
echo -e "          Resolves: macro redefined errors (clashing header sets)"
echo -e ""
echo -e "  ${GREEN}Fix 2b${NC}  Added hardware/samsung/ril/libril/include"
echo -e "          → hardware/samsung/ril/libril/Android.mk"
echo -e "          Resolves: RIL_UNSOL_* / RIL_REQUEST_* undeclared"
echo -e ""
echo -e "  ${GREEN}Fix 3${NC}   Verified/fixed include order in ril.cpp"
echo -e "          telephony/ril.h must precede vendor command headers"
echo -e ""
echo -e "${BOLD} Rebuild:${NC}"
echo -e "   source build/envsetup.sh"
echo -e "   breakfast a5ltechn"
echo -e "   mka bacon 2>&1 | tee build.log"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
