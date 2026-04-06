#!/bin/bash
# save as fix_bluetooth_sap.sh
# chmod +x fix_bluetooth_sap.sh
# ./fix_bluetooth_sap.sh

set -e

echo "========================================="
echo "Fixing Bluetooth SAP compilation errors"
echo "========================================="

cd /tmp/src/android

# Backup original file
if [ ! -f packages/apps/Bluetooth/Android.mk.bak ]; then
    echo "Creating backup..."
    cp packages/apps/Bluetooth/Android.mk packages/apps/Bluetooth/Android.mk.bak
fi

# Apply fixes to Android.mk
echo "Applying fixes to Android.mk..."

# Remove sap-api-java-static dependency
if grep -q "sap-api-java-static" packages/apps/Bluetooth/Android.mk; then
    echo "  - Removing sap-api-java-static dependency"
    sed -i '/sap-api-java-static/d' packages/apps/Bluetooth/Android.mk
fi

# Replace LOCAL_SRC_FILES line to exclude SAP directory
if grep -q "LOCAL_SRC_FILES := \$(call all-java-files-under, src)" packages/apps/Bluetooth/Android.mk; then
    echo "  - Modifying LOCAL_SRC_FILES to exclude SAP directory"
    sed -i '/LOCAL_SRC_FILES := \$(call all-java-files-under, src)/c\
ALL_SRC_FILES := $(call all-java-files-under, src)\
LOCAL_SRC_FILES := $(filter-out %/sap/%, $(ALL_SRC_FILES))' packages/apps/Bluetooth/Android.mk
fi

# Verify changes
echo ""
echo "Changes applied:"
echo "----------------"
grep -A2 "ALL_SRC_FILES :=" packages/apps/Bluetooth/Android.mk || echo "Check: ALL_SRC_FILES modification may need manual verification"
grep "sap-api" packages/apps/Bluetooth/Android.mk && echo "WARNING: sap-api still present" || echo "✓ sap-api-java-static removed"

# Clean Bluetooth intermediates
echo ""
echo "Cleaning Bluetooth build intermediates..."
rm -rf out/target/common/obj/APPS/Bluetooth_intermediates/

echo ""
echo "========================================="
echo "Fixes applied successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review changes: diff packages/apps/Bluetooth/Android.mk.bak packages/apps/Bluetooth/Android.mk"
echo "2. Resume build: make -j4 bacon"
echo ""

# Optional: Show diff
read -p "Show diff? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    diff -u packages/apps/Bluetooth/Android.mk.bak packages/apps/Bluetooth/Android.mk || true
fi
