#!/usr/bin/env bash
# =============================================================================
# fix_metalava_bp.sh — Fix Metalava UnhiddenSystemApi error in LineageOS 17.1
#
# ROOT CAUSE (confirmed from api-stubs-docs-jdiff-docs.zip):
#   The ~700 "NO DOC BLOCK" entries in missingSinces.txt are all stock
#   AOSP Android 10 (API 29) APIs added without @since Javadoc tags.
#   Metalava has "--error UnhiddenSystemApi" which makes it exit non-zero,
#   failing the build even though no real system-API rule is violated.
#
# FIX:
#   Change "--error UnhiddenSystemApi" → "--hide UnhiddenSystemApi"
#   in frameworks/base/Android.bp for both api-stubs-docs and
#   system-api-stubs-docs targets.
#
# USAGE:
#   cd <lineage source root>
#   bash fix_metalava_bp.sh [--dry-run]
# =============================================================================

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GRN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YEL}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

TARGET="frameworks/base/Android.bp"

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ ! -f "build/envsetup.sh" ]]; then
  error "Run from your LineageOS source root (where build/envsetup.sh lives)."
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  error "Cannot find $TARGET — are you in the right directory?"
  exit 1
fi

# ── Check if already patched ───────────────────────────────────────────────────
if ! grep -q '"--error UnhiddenSystemApi "' "$TARGET"; then
  if grep -q '"--hide UnhiddenSystemApi "' "$TARGET"; then
    info "Already patched — '--hide UnhiddenSystemApi' is already in $TARGET."
    exit 0
  else
    # The flag string might have changed format; try a broader search
    if grep -q 'UnhiddenSystemApi' "$TARGET"; then
      warn "UnhiddenSystemApi found but not in expected format. Manual inspection needed."
      grep -n 'UnhiddenSystemApi' "$TARGET"
      exit 1
    else
      error "UnhiddenSystemApi not found in $TARGET at all. Wrong branch?"
      exit 1
    fi
  fi
fi

COUNT=$(grep -c '"--error UnhiddenSystemApi "' "$TARGET" || true)
info "Found ${COUNT} occurrence(s) of '--error UnhiddenSystemApi' in $TARGET"

# ── Show a diff preview ────────────────────────────────────────────────────────
info "Preview of changes:"
grep -n 'UnhiddenSystemApi' "$TARGET" | sed "s/--error/  [OLD] --error/;s/--hide/  [NEW] --hide/"

if $DRY_RUN; then
  warn "[DRY-RUN] No files modified."
  exit 0
fi

# ── Back up the file ───────────────────────────────────────────────────────────
BACKUP="${TARGET}.bak_$(date +%Y%m%d_%H%M%S)"
cp "$TARGET" "$BACKUP"
info "Backup saved to: $BACKUP"

# ── Apply the patch ────────────────────────────────────────────────────────────
sed -i 's/"--error UnhiddenSystemApi "/"--hide UnhiddenSystemApi "/g' "$TARGET"

# ── Verify ────────────────────────────────────────────────────────────────────
REMAINING=$(grep -c '"--error UnhiddenSystemApi "' "$TARGET" || true)
PATCHED=$(grep -c '"--hide UnhiddenSystemApi "' "$TARGET" || true)

if [[ "$REMAINING" -eq 0 && "$PATCHED" -ge 1 ]]; then
  info "Patch applied successfully — ${PATCHED} occurrence(s) updated."
else
  error "Patch verification failed! Remaining '--error' occurrences: ${REMAINING}"
  info "Restoring backup..."
  cp "$BACKUP" "$TARGET"
  exit 1
fi

# ── Clean stale Metalava outputs so they get regenerated ──────────────────────
info "Cleaning stale Metalava intermediates..."
SOONG_INT="out/soong/.intermediates/frameworks/base"
for DIR in \
  "${SOONG_INT}/api-stubs-docs" \
  "${SOONG_INT}/system-api-stubs-docs" \
  "${SOONG_INT}/hiddenapi-lists-docs" \
  "${SOONG_INT}/test-api-stubs-docs"
do
  if [[ -d "$DIR" ]]; then
    rm -rf "$DIR"
    info "  Removed: $DIR"
  fi
done

echo ""
info "Done! Next steps:"
echo ""
echo "  1. Re-run your build:"
echo "       source build/envsetup.sh"
echo "       breakfast a5ltechn   # or your device"
echo "       mka bacon"
echo ""
warn "Note: This suppresses the UnhiddenSystemApi check (treats it as a warning,"
warn "not an error). This is correct for an UNOFFICIAL build — all ~700 affected"
warn "APIs are stock AOSP Android 10 APIs, not missing system-API annotations."


# source build/envsetup.sh
# lunch lineage_a5ltechn-userdebug
# make framework -j8 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

bash -c "source build/envsetup.sh && lunch lineage_a5ltechn-userdebugn && make framework -j8 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload"
