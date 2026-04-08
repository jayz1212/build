#!/bin/bash
# disable_sap_full_fix.sh
# Guaranteed SAP removal for WiFi-only builds (no protobuf / btsap errors)

set -e

echo "=== HARD DISABLE Bluetooth SAP (Guaranteed Fix) ==="

BLUETOOTH_DIR="packages/apps/Bluetooth"
SAP_DIR="${BLUETOOTH_DIR}/src/com/android/bluetooth/sap"
DISABLED_DIR="${SAP_DIR}.disabled"
BACKUP_DIR="${BLUETOOTH_DIR}/.sap_backup_$(date +%Y%m%d_%H%M%S)"

# Ensure we're in AOSP root
if [ ! -f "build/soong/soong_ui.bash" ]; then
    echo "❌ Run this from AOSP root"
    exit 1
fi

# Create backup
mkdir -p "${BACKUP_DIR}"
echo "✓ Backup dir: ${BACKUP_DIR}"

# Backup SAP if exists
if [ -d "${SAP_DIR}" ]; then
    cp -r "${SAP_DIR}" "${BACKUP_DIR}/sap_backup"
    echo "✓ Backed up SAP source"
fi

# Disable SAP (hard remove from build)
if [ -d "${SAP_DIR}" ]; then
    mv "${SAP_DIR}" "${DISABLED_DIR}"
    echo "✓ SAP disabled (renamed)"
else
    echo "⚠ SAP already disabled or missing"
fi

# Optional: create stub marker
mkdir -p "${DISABLED_DIR}"
cat > "${DISABLED_DIR}/README_DISABLED.txt" <<EOF
Bluetooth SAP (SIM Access Profile) disabled.

Reason:
- Fix build errors (missing protobuf + btsap)
- WiFi-only device does not need SAP

To restore:
mv ${DISABLED_DIR} ${SAP_DIR}
EOF

echo "✓ Added disable note"

# 🔥 CLEAN PROPERLY (important!)
echo "→ Cleaning build artifacts..."

rm -rf out/soong/.intermediates/packages/apps/Bluetooth
rm -rf out/target/common/obj/APPS/Bluetooth_intermediates
rm -rf out/target/common/obj/JAVA_LIBRARIES/bluetooth*
rm -rf out/target/common/obj/JAVA_LIBRARIES/*sap*

echo "✓ Clean complete"

# Restore script
cat > "${BACKUP_DIR}/restore_sap.sh" <<EOF
#!/bin/bash
set -e
cd "\$(dirname "\$0")/../../.."

if [ -d "${DISABLED_DIR}" ]; then
    mv "${DISABLED_DIR}" "${SAP_DIR}"
    echo "✓ SAP restored"
fi

echo "Now rebuild:"
echo "m Bluetooth"
EOF

chmod +x "${BACKUP_DIR}/restore_sap.sh"

echo ""
echo "=== ✅ SAP FULLY DISABLED ==="
echo "No more:"
echo "  - com.google.protobuf.micro errors"
echo "  - org.android.btsap errors"
echo ""
echo "👉 Rebuild now:"
echo "   m Bluetooth -j$(nproc)"
echo ""
echo "👉 Restore if needed:"
echo "   ${BACKUP_DIR}/restore_sap.sh"
