# Clean env
unset JAVA_HOME
export PATH=$(pwd)/prebuilts/jdk/jdk9/linux-x86/bin:$PATH
export _JAVA_OPTIONS="-Xmx6g"
export ALLOW_MISSING_DEPENDENCIES=true

# Clean broken intermediates
rm -rf out/soong/.intermediates/libcore

# Optional: resync libcore if suspicious
# repo sync libcore -j$(nproc)

# Rebuild safely
m core-platform-api-stubs -j1
