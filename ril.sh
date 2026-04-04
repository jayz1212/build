bash -c '
echo "====================================="
echo "[*] COMPLETE WIFI-ONLY PATCH (FINAL)"
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
# 1. REMOVE ALL RIL (no rename!)
# -----------------------------------
echo "[*] Removing all RIL sources..."

rm -rf hardware/ril
rm -rf hardware/ril.disabled
rm -rf hardware/samsung/ril
rm -rf hardware/samsung/ril.disabled

# -----------------------------------
# 2. Patch hardware/samsung/Android.mk
# -----------------------------------
SMK="hardware/samsung/Android.mk"

if [ -f "$SMK" ]; then
  echo "[*] Patching Samsung Android.mk"

  cp "$SMK" "$SMK.bak"

  # Remove ANY ril references
  sed -i "/ril/d" "$SMK"

  # Fix subdir include if present
  sed -i "s|include.*all-subdir-makefiles.*|subdirs := \$(filter-out ril, \$(call all-named-subdir-makefiles))\ninclude \$(subdirs)|g" "$SMK"
fi

# -----------------------------------
# 3. Device tree cleanup (SAFE)
# -----------------------------------
echo "[*] Cleaning device tree references..."

sed -i "/libril/d" "$DEVICE_DIR/device.mk" 2>/dev/null
sed -i "/rild/d" "$DEVICE_DIR/device.mk" 2>/dev/null
sed -i "/reference-ril/d" "$DEVICE_DIR/device.mk" 2>/dev/null

sed -i "/libril/d" "$DEVICE_DIR/BoardConfig.mk" 2>/dev/null
sed -i "/rild/d" "$DEVICE_DIR/BoardConfig.mk" 2>/dev/null

# -----------------------------------
# 4. Add WiFi-only config
# -----------------------------------
echo "[*] Adding WiFi-only configuration..."

grep -q "ro.radio.noril" "$DEVICE_DIR/device.mk" || cat >> "$DEVICE_DIR/device.mk" <<EOF

# WiFi-only configuration
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    persist.radio.multisim.config=none \\
    ro.telephony.default_network=0

# Prevent telephony crashes
PRODUCT_PACKAGES += \\
    TelephonyProviderStub
EOF

grep -q "TARGET_NO_TELEPHONY" "$DEVICE_DIR/BoardConfig.mk" || cat >> "$DEVICE_DIR/BoardConfig.mk" <<EOF

# Disable telephony
TARGET_NO_TELEPHONY := true
TARGET_NO_RADIOIMAGE := true
BOARD_PROVIDES_LIBRIL := true
EOF

# -----------------------------------
# 5. Clean build system (IMPORTANT)
# -----------------------------------
echo "[*] Cleaning build caches..."

rm -rf out/soong
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*
rm -rf out/target/product/*/obj/EXECUTABLES/rild*

# -----------------------------------
# DONE
# -----------------------------------
echo ""
echo "[✓] SUCCESS: FULL WIFI-ONLY BUILD READY"
echo ""
echo "Next commands:"
echo "  mka installclean"
echo "  mka bacon"
'
