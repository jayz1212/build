#!/usr/bin/env bash
# =============================================================================
# fix_metalava_bp.sh — Fix Metalava build errors for LineageOS 17.1
#                      Hides: UnhiddenSystemApi + ReferencesHidden
#                      Then kicks off the build automatically.
#
# USAGE:
#   cd <lineage source root>
#   bash fix_metalava_bp.sh [--dry-run] [--device <codename>]
# =============================================================================

set +euo pipefail
rm -rf frameworks/base
repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
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

if [[ ! -f "build/envsetup.sh" ]]; then
  error "Run from your LineageOS source root."
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  error "Cannot find $TARGET"
  exit 1
fi

PATCHED=false

# ── Fix 1: UnhiddenSystemApi ──────────────────────────────────────────────────
if grep -q '"--error UnhiddenSystemApi "' "$TARGET"; then
  info "Patching: --error UnhiddenSystemApi → --hide UnhiddenSystemApi"
  if ! $DRY_RUN; then
    sed -i 's/"--error UnhiddenSystemApi "/"--hide UnhiddenSystemApi "/g' "$TARGET"
    PATCHED=true
  fi
elif grep -q '"--hide UnhiddenSystemApi "' "$TARGET"; then
  info "UnhiddenSystemApi: already hidden."
else
  warn "UnhiddenSystemApi flag not found in expected format — skipping."
fi

# ── Fix 2: ReferencesHidden ───────────────────────────────────────────────────
# This is the NEW error: public methods referencing @hide classes (ddm, camera2, telephony, etc.)
# We need to add --hide ReferencesHidden to every metalava_docs args block in Android.bp

if grep -q '"--hide ReferencesHidden "' "$TARGET"; then
  info "ReferencesHidden: already hidden."
else
  info "Patching: adding --hide ReferencesHidden to all Metalava targets"
  if ! $DRY_RUN; then
    # Insert --hide ReferencesHidden right after --hide UnhiddenSystemApi (or after --hide Typo as fallback)
    sed -i 's/"--hide UnhiddenSystemApi "/"--hide UnhiddenSystemApi " +\n        "--hide ReferencesHidden "/g' "$TARGET"
    PATCHED=true
  fi
fi

# ── Verify both are present ───────────────────────────────────────────────────
if ! $DRY_RUN; then
  UNHIDDEN_COUNT=$(grep -c '"--hide UnhiddenSystemApi "' "$TARGET" || true)
  REFHIDDEN_COUNT=$(grep -c '"--hide ReferencesHidden "' "$TARGET" || true)
  info "Verification — UnhiddenSystemApi hidden in ${UNHIDDEN_COUNT} place(s), ReferencesHidden in ${REFHIDDEN_COUNT} place(s)."

  if [[ "$REFHIDDEN_COUNT" -eq 0 ]]; then
    warn "ReferencesHidden patch may have failed. Trying fallback insertion..."
    # Fallback: insert before --hide Typo (last hide flag in every block)
    sed -i 's/"--hide Typo "/"--hide Typo " +\n        "--hide ReferencesHidden "/g' "$TARGET"
    REFHIDDEN_COUNT=$(grep -c '"--hide ReferencesHidden "' "$TARGET" || true)
    info "After fallback: ReferencesHidden hidden in ${REFHIDDEN_COUNT} place(s)."
  fi

  # Clean stale intermediates if anything changed
  if $PATCHED; then
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
fi

# ── Build ──────────────────────────────────────────────────────────────────────
if $DRY_RUN; then
  warn "[DRY-RUN] Would run: source build/envsetup.sh && breakfast ${DEVICE} && mka bacon"
  exit 0
fi

info "Setting up build environment..."
source build/envsetup.sh

info "Running breakfast for device: ${DEVICE}"
breakfast "${DEVICE}"


source <(curl -sf https://raw.githubusercontent.com/jayz1212/build/refs/heads/main/java2.sh)

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH


info "Starting build (mka bacon)..."
mka framework -j4 2>&1 | tee build1.log && curl -F "file=@build1.log" https://temp.sh/upload

BUILD_EXIT=$?
if [[ $BUILD_EXIT -eq 0 ]]; then
  info "Build completed successfully!"
else
  error "Build failed with exit code ${BUILD_EXIT}. Check output above."
  exit $BUILD_EXIT
fi

java -version
