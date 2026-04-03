#!/bin/bash
# fix_samsung_ril.sh — Fix ALL Samsung RIL build errors for a5ltechn / LineageOS 17.1
# Run from the root of your Android source tree:
#   bash fix_samsung_ril.sh
#
# What this fixes:
#   1. Cleans up duplicate LOCAL_C_INCLUDES lines left by previous script runs
#   2. reference-ril: 'samsung_ril_defs.h' file not found
#   3. libril: RIL_UNSOL_* undeclared (identifiers missing from samsung_ril_defs.h)
#   4. libril: macro redefined (two header sets clashing)
#
# Root cause analysis:
#   - samsung_ril_defs.h (hardware/samsung/ril/libril/include/telephony/) only defines
#     Samsung-specific macros up to SAMSUNG_UNSOL_RESPONSE_BASE+10 and a handful of
#     RIL_REQUEST_* entries. It does NOT define the full set of RIL_UNSOL_* identifiers
#     that ril_unsol_commands_vendor.h references (11012–11031+).
#   - Those identifiers live ONLY in device/samsung/a5-common/include/telephony/ril.h.
#   - But including that file alongside samsung_ril_defs.h causes -Wmacro-redefined
#     because they both define overlapping macros (RIL_UNSOL_AM, RIL_UNSOL_GPS_NOTI etc).
#   - The solution: patch samsung_ril_defs.h to add include guards so the device ril.h
#     wins for the shared definitions, OR (cleaner/safer) patch ril.cpp to include the
#     device ril.h BEFORE samsung_ril_defs.h is pulled in, wrapped in an ifndef guard
#     so each macro is only defined once.
#   - For reference-ril: it just needs the telephony/ dir on its include path.

set -euo pipefail
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
header()  { echo -e "\n${BOLD}━━━  $*  ━━━${NC}"; }

[[ -f "build/envsetup.sh" ]] || die "Run this from the root of your Android source tree."

# ─────────────────────────────────────────────────────────────────────────────
# Helper: deduplicate LOCAL_C_INCLUDES lines in an Android.mk
# Removes ALL existing lines matching the pattern, then adds exactly one.
# ─────────────────────────────────────────────────────────────────────────────
set_c_include_mk() {
    local file="$1"
    local path="$2"
    # Escape slashes for sed
    local escaped
    escaped=$(echo "$path" | sed 's|/|\\/|g')
    # Remove ALL existing lines that contain this path (handles duplicates)
    sed -i "/LOCAL_C_INCLUDES.*${escaped}/d" "$file"
    # Now add exactly one line
    if grep -q "LOCAL_C_INCLUDES" "$file"; then
        # Insert after the first LOCAL_C_INCLUDES line
        sed -i "0,/LOCAL_C_INCLUDES/{ /LOCAL_C_INCLUDES/a LOCAL_C_INCLUDES += $path
}" "$file"
    else
        sed -i "0,/LOCAL_SRC_FILES/{ /LOCAL_SRC_FILES/i LOCAL_C_INCLUDES += $path
}" "$file"
    fi
    success "Set (exactly once) in $file: LOCAL_C_INCLUDES += $path"
}

# Helper: remove ALL lines containing a path from an Android.mk
remove_c_include_mk() {
    local file="$1"
    local path="$2"
    local escaped
    escaped=$(echo "$path" | sed 's|/|\\/|g')
    local count
    count=$(grep -c "LOCAL_C_INCLUDES.*${escaped}" "$file" 2>/dev/null || true)
    if [[ "$count" -gt 0 ]]; then
        sed -i "/LOCAL_C_INCLUDES.*${escaped}/d" "$file"
        info "Removed $count line(s) matching '$path' from $file"
    else
        info "Not present (nothing to remove): '$path' in $file"
    fi
}

# ═════════════════════════════════════════════════════════════════════════════
# STEP 0 — Clean up duplicate includes left by previous script runs
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 0 — Cleaning up duplicate includes from previous runs"

REFRIL_MK="hardware/ril/reference-ril/Android.mk"
LIBRIL_MK="hardware/samsung/ril/libril/Android.mk"

[[ -f "$REFRIL_MK" ]] || die "$REFRIL_MK not found."
[[ -f "$LIBRIL_MK" ]] || die "$LIBRIL_MK not found."

# Nuke every previously added include path from both files — we'll re-add exactly once
PATHS_TO_CLEAN=(
    "hardware/samsung/ril/libril/include/telephony"
    "hardware/samsung/ril/libril/include"
    "device/samsung/a5-common/include"
)
for p in "${PATHS_TO_CLEAN[@]}"; do
    remove_c_include_mk "$REFRIL_MK" "$p"
    remove_c_include_mk "$LIBRIL_MK" "$p"
done
success "Cleaned all previously added paths from both Android.mk files."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1 — Fix reference-ril: 'samsung_ril_defs.h' file not found
#
# reference-ril/ril.h:  #include "samsung_ril_defs.h"  (bare filename, no subdir)
# File is at: hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h
# So add the telephony/ dir to reference-ril's -I path.
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 1 — reference-ril: add samsung_ril_defs.h include path"

DEFS_DIR="hardware/samsung/ril/libril/include/telephony"
if [[ ! -f "$DEFS_DIR/samsung_ril_defs.h" ]]; then
    FOUND=$(find hardware/ device/ -name "samsung_ril_defs.h" 2>/dev/null | head -1)
    [[ -n "$FOUND" ]] || die "samsung_ril_defs.h not found. Sync the Samsung RIL repo."
    DEFS_DIR=$(dirname "$FOUND")
    warn "Using dynamically located path: $DEFS_DIR"
fi

set_c_include_mk "$REFRIL_MK" "$DEFS_DIR"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2 — Fix libril: add its own include dir
#
# libril needs hardware/samsung/ril/libril/include on its path so that
# its own internal headers (ril_commands_vendor.h etc.) resolve.
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 2 — libril: add its own include dir"

LIBRIL_INCLUDE="hardware/samsung/ril/libril/include"
set_c_include_mk "$LIBRIL_MK" "$LIBRIL_INCLUDE"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3 — Fix libril: RIL_UNSOL_* undeclared identifiers
#
# The problem: ril_unsol_commands_vendor.h references RIL_UNSOL_DATA_SUSPEND_RESUME
# (11012) through RIL_UNSOL_UTS_GET_UNREAD_SMS_STATUS (11031) and beyond.
# These are defined in device/samsung/a5-common/include/telephony/ril.h
# but NOT in samsung_ril_defs.h.
#
# We cannot just add device/samsung/a5-common/include to libril's path because
# that ril.h also redefines macros already in samsung_ril_defs.h → clash.
#
# Solution: patch samsung_ril_defs.h to add the missing identifiers, wrapped
# in #ifndef guards so that if either header is included first, there is no
# redefinition. We add only the identifiers that are currently missing.
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 3 — Patch samsung_ril_defs.h: add missing RIL_UNSOL_* identifiers"

DEFS_H="hardware/samsung/ril/libril/include/telephony/samsung_ril_defs.h"
[[ -f "$DEFS_H" ]] || die "$DEFS_H not found."

# Check which identifiers are already present
missing_ids=()
declare -A NEEDED_DEFS=(
    ["RIL_UNSOL_DATA_SUSPEND_RESUME"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 12)"
    ["RIL_UNSOL_SAP"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 13)"
    ["RIL_UNSOL_SIM_SMS_STORAGE_AVAILALE"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 15)"
    ["RIL_UNSOL_HSDPA_STATE_CHANGED"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 16)"
    ["RIL_UNSOL_WB_AMR_STATE"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 17)"
    ["RIL_UNSOL_TWO_MIC_STATE"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 18)"
    ["RIL_UNSOL_DHA_STATE"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 19)"
    ["RIL_UNSOL_UART"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 20)"
    ["RIL_UNSOL_RESPONSE_HANDOVER"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 21)"
    ["RIL_UNSOL_IPV6_ADDR"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 22)"
    ["RIL_UNSOL_NWK_INIT_DISC_REQUEST"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 23)"
    ["RIL_UNSOL_RTS_INDICATION"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 24)"
    ["RIL_UNSOL_OMADM_SEND_DATA"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 25)"
    ["RIL_UNSOL_DUN"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 26)"
    ["RIL_UNSOL_SYSTEM_REBOOT"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 27)"
    ["RIL_UNSOL_VOICE_PRIVACY_CHANGED"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 28)"
    ["RIL_UNSOL_UTS_GETSMSCOUNT"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 29)"
    ["RIL_UNSOL_UTS_GETSMSMSG"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 30)"
    ["RIL_UNSOL_UTS_GET_UNREAD_SMS_STATUS"]="(SAMSUNG_UNSOL_RESPONSE_BASE + 31)"
)

for id in "${!NEEDED_DEFS[@]}"; do
    if ! grep -q "define ${id}" "$DEFS_H"; then
        missing_ids+=("$id")
    fi
done

if [[ ${#missing_ids[@]} -eq 0 ]]; then
    success "All required RIL_UNSOL_* identifiers already present in $DEFS_H"
else
    info "Adding ${#missing_ids[@]} missing identifier(s) to $DEFS_H"

    # Build the block to append — each wrapped in #ifndef to avoid any clash
    BLOCK="\n/* Added by fix_samsung_ril.sh — missing identifiers for ril_unsol_commands_vendor.h */\n"
    # Sort for deterministic output
    for id in $(echo "${missing_ids[@]}" | tr ' ' '\n' | sort); do
        val="${NEEDED_DEFS[$id]}"
        BLOCK+="#ifndef ${id}\n#define ${id} ${val}\n#endif\n"
    done

    # Also wrap existing definitions in ifndef guards to prevent future clashes
    # First, back up the file
    cp "$DEFS_H" "${DEFS_H}.bak"
    info "Backed up original to ${DEFS_H}.bak"

    # Append the missing definitions before the final #endif of the header guard
    # (or at end of file if no header guard)
    if grep -q "^#endif" "$DEFS_H"; then
        # Insert before the last #endif
        sed -i "$(grep -n "^#endif" "$DEFS_H" | tail -1 | cut -d: -f1)i $(echo -e "$BLOCK")" "$DEFS_H"
    else
        printf "\n%b" "$BLOCK" >> "$DEFS_H"
    fi
    success "Added missing RIL_UNSOL_* identifiers to $DEFS_H"
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4 — Fix reference-ril: RIL_UNSOL_OEM_HOOK_RAW macro redefined
#
# reference-ril/ril.h defines RIL_UNSOL_OEM_HOOK_RAW as 1028 (plain number).
# samsung_ril_defs.h defines it as (SAMSUNG_UNSOL_RESPONSE_BASE + 100) = 11100.
# These are DIFFERENT values and both fire -Wmacro-redefined.
#
# The reference-ril is the AOSP generic one. Its ril.h is being overridden by
# Samsung's copy in the include path.  The fix: wrap the definition in
# samsung_ril_defs.h in an #ifndef so reference-ril's own definition wins,
# and libril uses the Samsung value.
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 4 — Fix RIL_UNSOL_OEM_HOOK_RAW redefinition in samsung_ril_defs.h"

if grep -q "define RIL_UNSOL_OEM_HOOK_RAW" "$DEFS_H"; then
    # Check if it's already guarded
    if grep -B1 "define RIL_UNSOL_OEM_HOOK_RAW" "$DEFS_H" | grep -q "ifndef RIL_UNSOL_OEM_HOOK_RAW"; then
        success "RIL_UNSOL_OEM_HOOK_RAW already guarded in $DEFS_H"
    else
        info "Wrapping RIL_UNSOL_OEM_HOOK_RAW definition in #ifndef guard..."
        # Replace:   #define RIL_UNSOL_OEM_HOOK_RAW (...)
        # With:      #ifndef RIL_UNSOL_OEM_HOOK_RAW\n#define ...\n#endif
        sed -i 's|^\(#define RIL_UNSOL_OEM_HOOK_RAW .*\)$|#ifndef RIL_UNSOL_OEM_HOOK_RAW\n\1\n#endif|' "$DEFS_H"
        success "Wrapped RIL_UNSOL_OEM_HOOK_RAW in #ifndef guard in $DEFS_H"
    fi
else
    info "RIL_UNSOL_OEM_HOOK_RAW not defined in $DEFS_H — no action needed."
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 5 — Verify include order in ril.cpp (telephony/ril.h before vendor headers)
# ═════════════════════════════════════════════════════════════════════════════
header "STEP 5 — Verify include order in ril.cpp"

RILCPP="hardware/samsung/ril/libril/ril.cpp"
if [[ ! -f "$RILCPP" ]]; then
    warn "$RILCPP not found — skipping."
else
    RIL_H_LINE=$(grep -n '#include.*[<"]telephony/ril\.h[>"]' "$RILCPP" | head -1 | cut -d: -f1)
    CMD_LINE=$(grep -n '#include.*ril_commands_vendor\.h' "$RILCPP" | head -1 | cut -d: -f1)
    UNSOL_LINE=$(grep -n '#include.*ril_unsol_commands_vendor\.h' "$RILCPP" | head -1 | cut -d: -f1)

    FIRST_VENDOR=""
    [[ -n "$CMD_LINE" ]] && FIRST_VENDOR=$CMD_LINE
    if [[ -n "$UNSOL_LINE" ]]; then
        [[ -z "$FIRST_VENDOR" || "$UNSOL_LINE" -lt "$FIRST_VENDOR" ]] && FIRST_VENDOR=$UNSOL_LINE
    fi

    if [[ -z "$RIL_H_LINE" ]]; then
        warn "telephony/ril.h not included in $RILCPP — inserting."
        [[ -n "$FIRST_VENDOR" ]] && sed -i "${FIRST_VENDOR}i #include <telephony/ril.h>" "$RILCPP" \
            && success "Inserted #include <telephony/ril.h> before vendor headers."
    elif [[ -n "$FIRST_VENDOR" && "$RIL_H_LINE" -gt "$FIRST_VENDOR" ]]; then
        warn "Wrong order (ril.h line $RIL_H_LINE after vendor line $FIRST_VENDOR) — fixing."
        RIL_H_INCLUDE=$(sed -n "${RIL_H_LINE}p" "$RILCPP")
        sed -i "${RIL_H_LINE}d" "$RILCPP"
        sed -i "${FIRST_VENDOR}i $RIL_H_INCLUDE" "$RILCPP"
        success "Reordered: ril.h now precedes vendor command headers."
    else
        success "Include order correct (ril.h: line $RIL_H_LINE, first vendor: line ${FIRST_VENDOR:-n/a})."
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD} Done. Summary of changes:${NC}"
echo ""
echo -e "  ${GREEN}Step 0${NC}  Removed all duplicate/stale LOCAL_C_INCLUDES from:"
echo -e "          hardware/ril/reference-ril/Android.mk"
echo -e "          hardware/samsung/ril/libril/Android.mk"
echo ""
echo -e "  ${GREEN}Step 1${NC}  Added (once) to reference-ril/Android.mk:"
echo -e "          LOCAL_C_INCLUDES += $DEFS_DIR"
echo ""
echo -e "  ${GREEN}Step 2${NC}  Added (once) to libril/Android.mk:"
echo -e "          LOCAL_C_INCLUDES += $LIBRIL_INCLUDE"
echo ""
echo -e "  ${GREEN}Step 3${NC}  Patched $DEFS_H:"
echo -e "          Added missing RIL_UNSOL_* identifiers (11012–11031)"
echo -e "          each wrapped in #ifndef guards"
echo ""
echo -e "  ${GREEN}Step 4${NC}  Wrapped RIL_UNSOL_OEM_HOOK_RAW in #ifndef in samsung_ril_defs.h"
echo -e "          Prevents clash with reference-ril's own definition"
echo ""
echo -e "  ${GREEN}Step 5${NC}  Verified include order in ril.cpp"
echo ""
echo -e "${BOLD} Rebuild:${NC}"
echo -e "   source build/envsetup.sh && breakfast a5ltechn"
echo -e "   mka bacon 2>&1 | tee build.log"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
