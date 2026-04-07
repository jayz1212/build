cd /tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/

# Test all the compiler variants
echo "Testing arm-linux-androidkernel-gcc:"
./arm-linux-androidkernel-gcc --version 2>&1 | head -1

echo -e "\nTesting mbt-bin-arm-linux-androidkernel-gcc:"
ls -la mbt-bin-arm-linux-androidkernel-gcc

# If it doesn't exist, create it
if [ ! -f mbt-bin-arm-linux-androidkernel-gcc ]; then
    echo "Creating missing mbt-bin-arm-linux-androidkernel-gcc..."
    sudo ln -sf arm-linux-androidkernel-gcc mbt-bin-arm-linux-androidkernel-gcc
    sudo ln -sf arm-linux-androidkernel-g++ mbt-bin-arm-linux-androidkernel-g++
fi
cd -

unset CC CXX LD AR NM STRIP OBJCOPY OBJDUMP READELF CLANG_TRIPLE
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=/tmp/src/android/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androidkernel-
export HOSTCC=clang
export HOSTCXX=clang++

# Verify the setup
echo "CROSS_COMPILE=$CROSS_COMPILE"
echo "Testing compiler:"
${CROSS_COMPILE}gcc --version | head -1

# Clean and rebuild
rm -rf out/target/product/a5ltechn/obj/KERNEL_OBJ

. build/envsetup.sh
brunch a5ltechn 2>&1 | tee build.log

# Upload to ix.ioe
curl -F "file=@build.log" https://temp.sh/upload
