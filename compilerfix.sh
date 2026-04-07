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
