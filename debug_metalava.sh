#!/usr/bin/env bash
# Runs the exact failing Metalava command without --quiet to expose the real error.
# Run from your LineageOS source root.

set +euo pipefail

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GRN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YEL}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SOONG_INT="out/soong/.intermediates/frameworks/base"
JDK="prebuilts/jdk/jdk9/linux-x86/bin/java"
METALAVA="out/soong/host/linux-x86/framework/metalava.jar"

if [[ ! -f "$METALAVA" ]]; then
  error "metalava.jar not found. Run a partial build first."
  exit 1
fi

# Rebuild the srcjars list first (needed if intermediates were cleaned)
info "Ensuring srcjars list exists for api-stubs-docs..."
SRCJARS_LIST="${SOONG_INT}/api-stubs-docs/android_common/srcjars/list"
RSP="${SOONG_INT}/api-stubs-docs/android_common/api-stubs-docs-stubs.srcjar.rsp"

if [[ ! -f "$SRCJARS_LIST" || ! -f "$RSP" ]]; then
  warn "srcjars/list or RSP not found — running a minimal build to regenerate them..."
  source build/envsetup.sh 2>/dev/null
  mka api-stubs-docs 2>&1 | tail -5 || true
fi

if [[ ! -f "$SRCJARS_LIST" || ! -f "$RSP" ]]; then
  error "Still missing intermediates. Run 'mka framework' once to let Soong generate them, then re-run this script."
  exit 1
fi

info "Running Metalava WITHOUT --quiet to reveal actual errors..."
info "Output will show in real time below:"
echo "================================================================"

"$JDK" -jar "$METALAVA" \
  -encoding UTF-8 -source 1.8 \
  "@${RSP}" \
  "@${SRCJARS_LIST}" \
  -bootclasspath \
    "${SOONG_INT}/../../libcore/mmodules/core_platform_api/core.platform.api.stubs/android_common/javac/core.platform.api.stubs.jar:\
out/soong/.intermediates/libcore/core-lambda-stubs/android_common/javac/core-lambda-stubs.jar" \
  -classpath \
    "${SOONG_INT}/ext/android_common/turbine-combined/ext.jar:\
${SOONG_INT}/framework/android_common/turbine-jarjar/framework.jar:\
${SOONG_INT}/media/updatable_media_stubs/android_common/turbine-combined/updatable_media_stubs.jar:\
out/soong/.intermediates/frameworks/opt/net/voip/voip-common/android_common/turbine-combined/voip-common.jar" \
  --no-banner --color --format=v2 \
  --hide UnhiddenSystemApi \
  --hide HiddenTypedefConstant --hide SuperfluousPrefix --hide AnnotationExtraction \
  --hide RequiresPermission --hide MissingPermission --hide BroadcastBehavior \
  --hide HiddenSuperclass --hide DeprecationMismatch --hide UnavailableSymbol \
  --hide SdkConstant --hide HiddenTypeParameter --hide Todo --hide Typo \
  --manifest frameworks/base/core/res/AndroidManifest.xml \
  --hide-package com.android.okhttp \
  --hide-package com.android.org.conscrypt \
  --hide-package com.android.server \
  --hide-package lineageos.platform \
  --hide-package org.lineageos.platform.internal \
  2>&1 | tee /tmp/metalava_debug.log

EXIT=${PIPESTATUS[0]}
echo "================================================================"

if [[ $EXIT -ne 0 ]]; then
  error "Metalava exited with code $EXIT"
  echo ""
  info "Filtering for actual errors:"
  grep -E "^.+\.java:[0-9]+: error:|^error:" /tmp/metalava_debug.log | head -40 || \
    grep -i "error\|exception\|fatal" /tmp/metalava_debug.log | head -40
  echo ""
  warn "Full output saved to: /tmp/metalava_debug.log"
else
  info "Metalava succeeded! The issue may be in a different target (hiddenapi-lists-docs or system-api-stubs-docs)."
fi
