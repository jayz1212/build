#!/bin/bash


# cd device/samsung/msm8916-common
# git fetch https://github.com/jayz1212/android_device_samsung_msm8916-common-1.git patch-1
# git cherry-pick ae2d8080142d1b4862c6ef51ab5e755a0556fc0d
# cd - 


# cd device/samsung/a5-common
# git fetch https://github.com/jayz1212/android_device_samsung_a5-common.git patch-1
# git cherry-pick e3427a6ba3592cd201efdf8f5359da9d9caa51fd
# cd - 

# cd device/samsung/a5ltechn
# git fetch https://github.com/jayz1212/android_device_samsung_a5ltechn.git patch-1
# git cherry-pick 5f126f96f5cd3c29c31cfd3390f14f923c99cbff
# cd - 


bash -c '
echo "====================================="
echo "[*] FULL RIL STRIP + WIFI-ONLY PATCH"
echo "====================================="

# Detect device
DEVICE_DIR=$(find device -type d -name "*a5ltechn*" | head -n 1)

if [ -z "$DEVICE_DIR" ]; then
  echo "[!] Device tree not found"
  exit 1
fi

echo "[*] Using device tree: $DEVICE_DIR"

# -----------------------------------
# 1. BoardConfig fixes
# -----------------------------------
BC="$DEVICE_DIR/BoardConfig.mk"
if [ -f "$BC" ]; then
  echo "[*] Patching BoardConfig.mk"
  grep -q "BOARD_PROVIDES_LIBRIL" "$BC" || echo "BOARD_PROVIDES_LIBRIL := true" >> "$BC"
  grep -q "TARGET_NO_RADIOIMAGE" "$BC" || echo "TARGET_NO_RADIOIMAGE := true" >> "$BC"
  grep -q "TARGET_NO_TELEPHONY" "$BC" || echo "TARGET_NO_TELEPHONY := true" >> "$BC"
fi

# -----------------------------------
# 2. device.mk cleanup
# -----------------------------------
DMK="$DEVICE_DIR/device.mk"
if [ -f "$DMK" ]; then
  echo "[*] Cleaning device.mk (removing RIL packages)"

  sed -i "/libril/d" "$DMK"
  sed -i "/rild/d" "$DMK"
  sed -i "/reference-ril/d" "$DMK"

  # WiFi-only props
  grep -q "ro.radio.noril" "$DMK" || cat >> "$DMK" <<EOF

# WiFi-only (RIL disabled)
PRODUCT_PROPERTY_OVERRIDES += \\
    ro.radio.noril=true \\
    persist.radio.multisim.config=none \\
    ro.telephony.default_network=0
EOF

  # Stub telephony
  grep -q "TelephonyProviderStub" "$DMK" || cat >> "$DMK" <<EOF

# Stub telephony (prevents crashes)
PRODUCT_PACKAGES += \\
    TelephonyProviderStub
EOF
fi

# -----------------------------------
# 3. Disable Samsung RIL folder
# -----------------------------------
if [ -d "hardware/samsung/ril" ]; then
  echo "[*] Disabling Samsung RIL folder"
  mv hardware/samsung/ril hardware/samsung/ril.disabled 2>/dev/null
fi

# -----------------------------------
# 4. Fix hardware/samsung/Android.mk
# -----------------------------------
SMK="hardware/samsung/Android.mk"

if [ -f "$SMK" ]; then
  echo "[*] Fixing Android.mk include (exclude ril)"

  cp "$SMK" "$SMK.bak"

  awk '"'"'
  /include \$\(call all-subdir-makefiles\)/ {
      print "# patched: exclude ril"
      print "subdirs := \$(filter-out ril ril.disabled, \$(call all-named-subdir-makefiles))"
      print "include \$(subdirs)"
      next
  }
  { print }
  '"'"' "$SMK" > "$SMK.tmp" && mv "$SMK.tmp" "$SMK"
fi

# -----------------------------------
# 5. Clean old RIL build artifacts
# -----------------------------------
echo "[*] Cleaning old RIL intermediates..."
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*

# -----------------------------------
# DONE
# -----------------------------------
echo ""
echo "[✓] ALL DONE"
echo "→ RIL removed"
echo "→ Android.mk fixed"
echo "→ WiFi-only enforced"
echo ""
echo "Next:"
echo "  mka installclean"
echo "  mka bacon"
'
