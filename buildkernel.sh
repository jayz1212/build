#!/usr/bin/env bash
set -e

echo "🔥 Starting FULL Kernel Auto-Fix..."

# ===== PATHS =====
ANDROID_DIR="/tmp/src/android"
KERNEL_DIR="$ANDROID_DIR/kernel/samsung/msm8916"
OUT_DIR="$ANDROID_DIR/out/target/product/a5ltechn/obj/KERNEL_OBJ"

TOOLCHAIN="$ANDROID_DIR/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

# ===== FIX CROSS_COMPILE =====
echo "✔ Fixing CROSS_COMPILE"
export CROSS_COMPILE="$TOOLCHAIN"
export ARCH=arm

# ===== SANITY CHECK =====
if [[ ! -f "${CROSS_COMPILE}gcc" ]]; then
    echo "❌ Toolchain not found!"
    echo "Expected: ${CROSS_COMPILE}gcc"
    exit 1
fi

echo "✔ Toolchain OK: ${CROSS_COMPILE}gcc"

# ===== CLEAN BROKEN OUTPUT =====
echo "✔ Cleaning old kernel output"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$KERNEL_DIR"

# ===== AUTO-DETECT DEFCONFIG =====
echo "🔍 Detecting defconfig..."

DEFCONFIG=$(find arch/arm/configs -name "*a5ltechn*" | head -n 1 | xargs -n1 basename)

if [[ -z "$DEFCONFIG" ]]; then
    echo "⚠️ Could not auto-detect defconfig, trying fallback..."
    DEFCONFIG="msm8916_defconfig"
fi

echo "✔ Using defconfig: $DEFCONFIG"

# ===== GENERATE CONFIG =====
echo "⚙️ Generating .config..."

make O="$OUT_DIR" \
     ARCH=arm \
     CROSS_COMPILE="$CROSS_COMPILE" \
     "$DEFCONFIG"

# Ensure config is valid
make O="$OUT_DIR" \
     ARCH=arm \
     CROSS_COMPILE="$CROSS_COMPILE" \
     oldconfig

# ===== BUILD KERNEL =====
echo "⚡ Building kernel..."

make -j$(nproc) \
     O="$OUT_DIR" \
     ARCH=arm \
     CROSS_COMPILE="$CROSS_COMPILE" \
     zImage

# ===== BUILD DTBs (if needed) =====
if grep -q '^CONFIG_OF=y' "$OUT_DIR/.config"; then
    echo "🌳 Building DTBs..."
    make -j$(nproc) \
         O="$OUT_DIR" \
         ARCH=arm \
         CROSS_COMPILE="$CROSS_COMPILE" \
         dtbs
fi

# ===== BUILD MODULES (if needed) =====
if grep -q '=m' "$OUT_DIR/.config"; then
    echo "📦 Building modules..."
    make -j$(nproc) \
         O="$OUT_DIR" \
         ARCH=arm \
         CROSS_COMPILE="$CROSS_COMPILE" \
         modules
fi

echo "✅ Kernel build completed successfully!"
