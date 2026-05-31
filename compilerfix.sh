#!/usr/bin/env bash
set -e

echo "🔥 Applying FULL kernel/toolchain fix..."

# ===== 1. CLEAN BAD ENV =====
echo "✔ Resetting environment"
unset CROSS_COMPILE

# ===== 2. SET CORRECT TOOLCHAIN =====
TOOLCHAIN="/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

if [ ! -f "${TOOLCHAIN}gcc" ]; then
    echo "❌ Toolchain not found!"
    echo "Expected: ${TOOLCHAIN}gcc"
    exit 1
fi

export CROSS_COMPILE=$TOOLCHAIN
echo "✔ CROSS_COMPILE set to:"
echo "   $CROSS_COMPILE"

# ===== 3. FIX ALL WRONG PREFIXES =====
echo "✔ Replacing androidkernel → androideabi (global fix)"

grep -rl "androidkernel-" device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/androidkernel-/androideabi-/g' "$file"
done

# ===== 4. REMOVE LEADING SPACE BUG =====
echo "✔ Fixing leading space in CROSS_COMPILE"

grep -rl 'CROSS_COMPILE=" ' device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/CROSS_COMPILE=" /CROSS_COMPILE="/g' "$file"
done

grep -rl "CROSS_COMPILE= " device kernel vendor 2>/dev/null | while read -r file; do
    sed -i 's/CROSS_COMPILE= /CROSS_COMPILE=/g' "$file"
done

# ===== 5. FORCE OVERRIDE IN BOARD CONFIG =====
echo "✔ Forcing correct CROSS_COMPILE in BoardConfig"

BOARD_FILES=$(find device -name "BoardConfig*.mk" 2>/dev/null)

for f in $BOARD_FILES; do
    sed -i '/CROSS_COMPILE/d' "$f"
    echo "CROSS_COMPILE := $TOOLCHAIN" >> "$f"
done

# ===== 6. CLEAN OLD KERNEL BUILD =====
echo "✔ Cleaning old kernel build"

rm -rf out/target/product/*/obj/KERNEL_OBJ

# ===== 7. VERIFY =====
echo "✔ Verifying toolchain..."
if ! command -v ${CROSS_COMPILE}gcc >/dev/null 2>&1; then
    echo "❌ Toolchain not usable!"
    exit 1
fi

echo "🚀 Kernel fix applied successfully!"
