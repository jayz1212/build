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
echo "[*] Disabling RIL / Telephony..."

DEVICE_DIR=$(find device -type d -name "*a5ltechn*" | head -n 1)

if [ -z "$DEVICE_DIR" ]; then
  echo "[!] Device tree not found"
  exit 1
fi

echo "[*] Found device tree: $DEVICE_DIR"

# 1. BoardConfig flags
BC="$DEVICE_DIR/BoardConfig.mk"
if [ -f "$BC" ]; then
  grep -q "BOARD_PROVIDES_LIBRIL" "$BC" || echo "BOARD_PROVIDES_LIBRIL := true" >> "$BC"
  grep -q "TARGET_NO_RADIOIMAGE" "$BC" || echo "TARGET_NO_RADIOIMAGE := true" >> "$BC"
fi

# 2. device.mk cleanup
DMK="$DEVICE_DIR/device.mk"
if [ -f "$DMK" ]; then
  sed -i "/libril/d" "$DMK"
  sed -i "/rild/d" "$DMK"
  sed -i "/reference-ril/d" "$DMK"

  # add properties if missing
  grep -q "ro.radio.noril" "$DMK" || cat >> "$DMK" <<EOF

# Disable RIL (WiFi-only)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.radio.noril=true \
    persist.radio.multisim.config=none \
    ro.telephony.default_network=0
EOF
fi

# 3. Remove Samsung RIL from build (safe exclusion)
if [ -d "hardware/samsung/ril" ]; then
  echo "[*] Disabling Samsung RIL"
  mv hardware/samsung/ril hardware/samsung/ril.disabled 2>/dev/null
fi

# 4. Remove reference RIL usage
if [ -d "hardware/ril" ]; then
  echo "[*] Keeping hardware/ril but build won'\''t use it"
fi

# 5. Clean old intermediates (important)
echo "[*] Cleaning RIL intermediates..."
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*

echo "[✓] RIL fully disabled. Build is now WiFi-only."
'
