#!/bin/bash
set -e

echo "🔥 Applying FULL kernel build fixes..."

# =========================

# 1. Force correct toolchain

# =========================

echo "✔ Setting correct CROSS_COMPILE"
export CROSS_COMPILE=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export TARGET_KERNEL_CROSS_COMPILE=$CROSS_COMPILE

# =========================

# 2. Remove broken mbt wrapper from PATH

# =========================

echo "✔ Cleaning PATH (removing mbt wrapper)"
export PATH=$(echo $PATH | tr ':' '\n' | grep -v 'mbt' | paste -sd:)

# =========================

# 3. Fix any accidental androidkernel usage (just in case)

# =========================

echo "✔ Replacing androidkernel toolchain references"
echo "✔ Fast patch: androidkernel → androideabi"

sed -i 's/arm-linux-androidkernel-/arm-linux-androideabi-/g' \
device/samsung/a5ltechn/BoardConfig.mk 2>/dev/null || true

sed -i 's/arm-linux-androidkernel-/arm-linux-androideabi-/g' \
device/samsung/a5ltechn/*.mk 2>/dev/null || true

sed -i 's/arm-linux-androidkernel-/arm-linux-androideabi-/g' \
kernel/samsung/msm8916/Makefile 2>/dev/null || true



# =========================

# 4. Disable stack protector (required for old msm8916 kernel)

# =========================

echo "✔ Disabling STACKPROTECTOR"
find kernel/samsung/msm8916 -type f -name "*defconfig" -exec 
sed -i 's/CONFIG_CC_STACKPROTECTOR_REGULAR=y/# CONFIG_CC_STACKPROTECTOR is not set/g' {} ;

# =========================

# 5. Clean kernel build

# =========================

echo "✔ Cleaning old kernel build"
rm -rf out/target/product/a5ltechn/obj/KERNEL_OBJ

# =========================

# 6. Verify toolchain exists

# =========================

echo "✔ Verifying toolchain"
ls /tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-gcc >/dev/null

# =========================

# 7. Start build

# =========================

echo "🚀 Building bootimage..."

. build/envsetup.sh
lunch lineage_a5ltechn-userdebug
mka bootimage -j$(nproc)

echo "✅ DONE — if it fails again, send the NEXT error only."
