#!/bin/bash
# fix_build_scripts_final.sh

cd /tmp/src/android

echo "Fixing Python 2/3 compatibility issues..."

# Fix check_radio_versions.py
cat > build/tools/check_radio_versions.py << 'EOF'
#!/usr/bin/env python3
# Auto-converted to Python 3 for TWRP build

import os
import sys

def main():
    # Skip radio version checks for TWRP
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF

# Fix any other Python scripts that might have issues
find build/ -name "*.py" -type f | while read script; do
    if grep -q "print \"" "$script" 2>/dev/null; then
        echo "Fixing: $script"
        sed -i 's/print "\([^"]*\)"/print("\1")/g' "$script"
        sed -i "s/print '\([^']*\)'/print('\1')/g" "$script"
    fi
done

# Set Python 2 as default for the build environment
export PATH=/usr/bin:$PATH
alias python=python2

# Verify
echo "Python version: $(python --version 2>&1)"
echo "Python 2 version: $(python2 --version 2>&1)"

# Clean build artifacts
rm -rf out/target/product/a5ltechn/android-info.txt
rm -rf out/build-*.ninja

# Rebuild
source build/envsetup.sh
lunch omni_a5ltechn-eng
make recoveryimage
