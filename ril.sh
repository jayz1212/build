bash -c '
echo "====================================="
echo "[*] HARD RIL STRIP (ULTIMATE FIX)"
echo "====================================="

DEVICE_DIR=$(find device -type d -name "*a5ltechn*" | head -n 1)
[ -z "$DEVICE_DIR" ] && echo "[!] Device tree not found" && exit 1

echo "[*] Device: $DEVICE_DIR"

# -----------------------------------
# 1. BoardConfig
# -----------------------------------
BC="$DEVICE_DIR/BoardConfig.mk"
[ -f "$BC" ] && {
  echo "[*] Patching BoardConfig"
  grep -q "TARGET_NO_TELEPHONY" "$BC" || echo "TARGET_NO_TELEPHONY := true" >> "$BC"
  grep -q "TARGET_NO_RADIOIMAGE" "$BC" || echo "TARGET_NO_RADIOIMAGE := true" >> "$BC"
  grep -q "BOARD_PROVIDES_LIBRIL" "$BC" || echo "BOARD_PROVIDES_LIBRIL := true" >> "$BC"
}

# -----------------------------------
# 2. device.mk
# -----------------------------------
DMK="$DEVICE_DIR/device.mk"
[ -f "$DMK" ] && {
  echo "[*] Cleaning device.mk"

  sed -i "/ril/d" "$DMK"

  grep -q "ro.radio.noril" "$DMK" || cat >> "$DMK" <<EOF

PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    persist.radio.multisim.config=none \\
    ro.telephony.default_network=0

PRODUCT_PACKAGES += \\
    TelephonyProviderStub
EOF
}

# -----------------------------------
# 3. Remove Samsung RIL completely
# -----------------------------------
if [ -d "hardware/samsung/ril" ]; then
  echo "[*] Removing Samsung RIL folder completely"
  rm -rf hardware/samsung/ril
fi

# -----------------------------------
# 4. HARD PATCH Android.mk
# -----------------------------------
SMK="hardware/samsung/Android.mk"
if [ -f "$SMK" ]; then
  echo "[*] HARD patching Android.mk"

  cp "$SMK" "$SMK.bak"

  # REMOVE any direct ril includes
  sed -i "/ril/d" "$SMK"

  # Replace generic include safely
  sed -i "s|include.*all-subdir-makefiles.*|subdirs := \$(filter-out ril, \$(call all-named-subdir-makefiles))\ninclude \$(subdirs)|g" "$SMK"
fi

# -----------------------------------
# 5. Clean intermediates
# -----------------------------------
echo "[*] Cleaning build artifacts"
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*

echo ""
echo "[✓] RIL FULLY NUKED"
echo "Now run:"
echo "  mka installclean"
echo "  mka bacon"
'
