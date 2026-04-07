#!/bin/bash

# =========================

# Strict & safe mode

# =========================

set -eo pipefail
shopt -s nullglob

echo "🔥 Applying FULL kernel build fixes..."

# =========================

# 1. Force correct toolchain

# =========================

echo "✔ Setting correct CROSS_COMPILE"
export CROSS_COMPILE=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export TARGET_KERNEL_CROSS_COMPILE="$CROSS_COMPILE"

# =========================

# 2. Remove broken mbt wrapper from PATH

# =========================

echo "✔ Cleaning PATH (removing mbt wrapper)"
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v 'mbt' | paste -sd: || true)

# =========================

# 3. Fix androidkernel usage (curl-safe)

# =========================

echo "✔ Fast patch: androidkernel → androideabi"

for f in device/samsung/a5ltechn/BoardConfig.mk device/samsung/a5ltechn/*.mk kernel/samsung/msm8916/Makefile; do
    [ -f "$f" ] && sed -i 's/arm-linux-androidkernel-/arm-linux-androideabi-/g' "$f"
done

# Optional check (safe with set -e)

if grep -rq "androidkernel" device/samsung/a5ltechn 2>/dev/null; then
echo "⚠ WARNING: androidkernel still found somewhere"
else
echo "✔ No androidkernel references found"
fi

# =========================

# 4. Disable stack protector

# =========================

echo "✔ Disabling STACKPROTECTOR"

for f in kernel/samsung/msm8916/arch/arm/configs/*defconfig; do
if [ -f "$f" ]; then
sed -i 's/CONFIG_CC_STACKPROTECTOR_REGULAR=y/# CONFIG_CC_STACKPROTECTOR is not set/g' "$f"
fi
done

# =========================

# 5. Clean kernel build

# =========================

echo "✔ Cleaning old kernel build"
rm -rf out/target/product/a5ltechn/obj/KERNEL_OBJ

# =========================

# 6. Verify toolchain exists

# =========================

echo "✔ Verifying toolchain"

TOOLCHAIN=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-gcc

if [ ! -f "$TOOLCHAIN" ]; then
echo "❌ Toolchain missing!"
exit 1
fi

# =========================

# 7. Start build

# =========================

echo "🚀 Building bootimages..."
set +u
. build/envsetup.sh
lunch lineage_a5ltechn-userdebug

mka bootimage -j$(nproc)

echo "✅ DONE — if it fails again, send ONLY the next error."
