#!/usr/bin/env bash
# =============================================================================
# fix_metalava_bp.sh — Fix Metalava UnhiddenSystemApi error in LineageOS 17.1
#                      then kick off the build automatically.
#
# USAGE:
#   cd <lineage source root>
#   bash fix_metalava_bp.sh [--dry-run] [--device <codename>]
#
# Default device: a5ltechn
# =============================================================================

set -uo pipefail   # no -e so build errors surface naturally

DRY_RUN=false
DEVICE="a5ltechn"

for ((i=1; i<=$#; i++)); do
  arg="${!i}"
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --device)  j=$((i+1)); DEVICE="${!j}" ;;
    --device=*) DEVICE="${arg#--device=}" ;;
  esac
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
  error "Cannot find $TARGET"
  exit 1
fi

# ── Patch (skip if already done) ──────────────────────────────────────────────
if grep -q '"--error UnhiddenSystemApi "' "$TARGET"; then
  info "Applying patch: --error UnhiddenSystemApi → --hide UnhiddenSystemApi"

  if $DRY_RUN; then
    warn "[DRY-RUN] Would patch $TARGET — skipping."
  else
    BACKUP="${TARGET}.bak_$(date +%Y%m%d_%H%M%S)"
    cp "$TARGET" "$BACKUP"
    info "Backup saved: $BACKUP"

    sed -i 's/"--error UnhiddenSystemApi "/"--hide UnhiddenSystemApi "/g' "$TARGET"

    REMAINING=$(grep -c '"--error UnhiddenSystemApi "' "$TARGET" || true)
    if [[ "$REMAINING" -ne 0 ]]; then
      error "Patch failed — restoring backup."
      cp "$BACKUP" "$TARGET"
      exit 1
    fi
    info "Patch applied successfully."

    # Clean stale Metalava intermediates
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
  fi

elif grep -q '"--hide UnhiddenSystemApi "' "$TARGET"; then
  info "Already patched — proceeding directly to build."

else
  warn "UnhiddenSystemApi not found in expected format in $TARGET"
  grep -n 'UnhiddenSystemApi' "$TARGET" || true
  warn "Attempting build anyway..."
fi

# ── Build ──────────────────────────────────────────────────────────────────────
if $DRY_RUN; then
  warn "[DRY-RUN] Would now run: source build/envsetup.sh && breakfast ${DEVICE} && mka bacon"
  exit 0
fi

info "Setting up build environment..."
set +u
source build/envsetup.sh
set -u

info "Running breakfast for device: ${DEVICE}"
breakfast "${DEVICE}"

info "Starting build (mka bacon)..."
mka framework -j8

BUILD_EXIT=$?
if [[ $BUILD_EXIT -eq 0 ]]; then
  info "Build completed successfully!"
else
  error "Build failed with exit code ${BUILD_EXIT}. Check output above."
  exit $BUILD_EXIT
fi



# source build/envsetup.sh
# lunch lineage_a5ltechn-userdebug
# make framework -j8 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

#bash -c "source build/envsetup.sh && lunch lineage_a5ltechn-userdebugn && make framework -j8 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload"
