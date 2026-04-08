#!/bin/bash
# sap_disabler.sh - Safely disable SAP for WiFi-only builds

set -e  # Exit on any error

BLUETOOTH_DIR="packages/apps/Bluetooth"
ANDROID_BP="${BLUETOOTH_DIR}/Android.bp"
SAP_DIR="${BLUETOOTH_DIR}/src/com/android/bluetooth/sap"
BACKUP_DIR="${BLUETOOTH_DIR}/.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Bluetooth SAP Disabler for WiFi-Only Build ==="

# Check if we're in AOSP root
if [ ! -f "build/soong/soong_ui.bash" ]; then
    echo "ERROR: Must run from AOSP root directory"
    exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo "✓ Created backup directory: ${BACKUP_DIR}"

# Backup Android.bp
if [ -f "${ANDROID_BP}" ]; then
    cp "${ANDROID_BP}" "${BACKUP_DIR}/Android.bp.backup"
    echo "✓ Backed up Android.bp"
fi

# Method 1: Try to modify Android.bp
modify_android_bp() {
    echo "→ Attempting to modify Android.bp..."
    
    # Check if exclude_srcs already exists
    if grep -q "exclude_srcs:" "${ANDROID_BP}"; then
        # Append to existing exclude_srcs
        sed -i '/exclude_srcs:/,/\]/ {
            /\]/ s/\]/    "src\/com\/android\/bluetooth\/sap\/\*\*\/\*\.java",\n\]/
        }' "${ANDROID_BP}"
        echo "✓ Added SAP to existing exclude_srcs"
    else
        # Add new exclude_srcs after the name line
        sed -i '/name: "Bluetooth"/a\    exclude_srcs: ["src/com/android/bluetooth/sap/**/*.java"],' "${ANDROID_BP}"
        echo "✓ Added exclude_srcs to Android.bp"
    fi
}

# Method 2: Rename SAP directory (fallback)
rename_sap_dir() {
    echo "→ Renaming SAP directory as fallback..."
    
    if [ -d "${SAP_DIR}" ]; then
        mv "${SAP_DIR}" "${SAP_DIR}.disabled"
        echo "✓ Renamed ${SAP_DIR} → ${SAP_DIR}.disabled"
        
        # Create a note file
        cat > "${SAP_DIR}.disabled/README.txt" << EOF
SAP (SIM Access Profile) disabled for WiFi-only build.
To restore: mv ${SAP_DIR}.disabled ${SAP_DIR}
Disabled on: $(date)
EOF
        echo "✓ Added restoration instructions"
    else
        echo "! SAP directory not found (may already be disabled)"
    fi
}

# Try modification, fallback to rename if it fails
if modify_android_bp; then
    DISABLE_METHOD="android_bp"
else
    echo "! Android.bp modification failed, using rename method"
    rename_sap_dir
    DISABLE_METHOD="rename"
fi

# Clean build artifacts
echo "→ Cleaning Bluetooth build artifacts..."
rm -rf out/target/common/obj/APPS/Bluetooth_intermediates/ 2>/dev/null || true
rm -rf out/target/common/obj/JAVA_LIBRARIES/bluetooth-* 2>/dev/null || true
echo "✓ Cleaned build cache"

# Create restore script
cat > "${BACKUP_DIR}/restore.sh" << 'EOF'
#!/bin/bash
# Restore SAP functionality
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOSP_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

cd "${AOSP_ROOT}"

if [ -f "${SCRIPT_DIR}/Android.bp.backup" ]; then
    cp "${SCRIPT_DIR}/Android.bp.backup" packages/apps/Bluetooth/Android.bp
    echo "✓ Restored Android.bp"
fi

if [ -d "packages/apps/Bluetooth/src/com/android/bluetooth/sap.disabled" ]; then
    mv packages/apps/Bluetooth/src/com/android/bluetooth/sap.disabled \
       packages/apps/Bluetooth/src/com/android/bluetooth/sap
    echo "✓ Restored SAP directory"
fi

echo "SAP functionality restored. Run 'make Bluetooth' to rebuild."
EOF
chmod +x "${BACKUP_DIR}/restore.sh"
echo "✓ Created restore script: ${BACKUP_DIR}/restore.sh"

# Summary
echo ""
echo "=== SAP Successfully Disabled ==="
echo "Method used: ${DISABLE_METHOD}"
echo "Backup location: ${BACKUP_DIR}"
echo ""
echo "To rebuild Bluetooth:"
echo "  make Bluetooth"
echo ""
echo "To restore SAP functionality:"
echo "  ${BACKUP_DIR}/restore.sh"
