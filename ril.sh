bash -c '
echo "====================================="
echo "[*] COMPLETE WIFI-ONLY BUILD PATCH"
echo "====================================="

# -----------------------------------
# Detect device
# -----------------------------------
DEVICE_DIR=$(find device -type d -name "*a5ltechn*" | head -n 1)

if [ -z "$DEVICE_DIR" ]; then
  echo "[!] Device tree not found"
  exit 1
fi

echo "[*] Device: $DEVICE_DIR"

# -----------------------------------
# 1. REMOVE ALL RIL (NO RENAME)
# -----------------------------------
echo "[*] Removing all RIL sources..."

rm -rf hardware/ril
rm -rf hardware/ril.disabled
rm -rf hardware/samsung/ril
rm -rf hardware/samsung/ril.disabled

# -----------------------------------
# 2. PATCH Samsung Android.mk
# -----------------------------------
SMK="hardware/samsung/Android.mk"

if [ -f "$SMK" ]; then
  echo "[*] Fixing Samsung Android.mk"
  cp "$SMK" "$SMK.bak"

  sed -i "/ril/d" "$SMK"
  sed -i "s|include.*all-subdir-makefiles.*|subdirs := \$(filter-out ril, \$(call all-named-subdir-makefiles))\ninclude \$(subdirs)|g" "$SMK"
fi

# -----------------------------------
# 3. CLEAN DEVICE TREE
# -----------------------------------
echo "[*] Cleaning device tree..."

sed -i "/libril/d" "$DEVICE_DIR/device.mk" 2>/dev/null
sed -i "/rild/d" "$DEVICE_DIR/device.mk" 2>/dev/null
sed -i "/reference-ril/d" "$DEVICE_DIR/device.mk" 2>/dev/null

sed -i "/libril/d" "$DEVICE_DIR/BoardConfig.mk" 2>/dev/null
sed -i "/rild/d" "$DEVICE_DIR/BoardConfig.mk" 2>/dev/null

# -----------------------------------
# 4. ADD WIFI-ONLY CONFIG
# -----------------------------------
echo "[*] Adding WiFi-only config..."

grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only configuration
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    persist.radio.multisim.config=none \\
    ro.telephony.default_network=0

PRODUCT_PACKAGES += \\
    TelephonyProviderStub
EOF

grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
BOARD_PROVIDES_LIBRIL := true
EOF

# -----------------------------------
# 5. FIX BLUETOOTH SAP (NEW)
# -----------------------------------
echo "[*] Fixing Bluetooth SAP dependency..."

BTMK="packages/apps/Bluetooth/Android.mk"
[ -f "$BTMK" ] && sed -i "/sap-api-java-static/d" "$BTMK"

QBTMK="vendor/qcom/opensource/commonsys/packages/apps/Bluetooth/Android.mk"
[ -f "$QBTMK" ] && sed -i "/sap-api-java-static/d" "$QBTMK"

# -----------------------------------
# 6. CLEAN BUILD SYSTEM
# -----------------------------------
echo "[*] Cleaning build cache..."

rm -rf out/soong
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*
rm -rf out/target/product/*/obj/EXECUTABLES/rild*

# -----------------------------------
# DONE
# -----------------------------------
echo ""
echo "[✓] ALL FIXES APPLIED SUCCESSFULLY"
echo ""
echo "Next steps:"
echo "  mka installclean"
echo "  mka bacon"
'
