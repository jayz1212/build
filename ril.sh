bash -c '
echo "====================================="
echo "[*] FINAL RIL REMOVAL (FAST & SAFE)"
echo "====================================="

# -----------------------------------
# 1. Disable AOSP RIL safely
# -----------------------------------
if [ -d "hardware/ril" ]; then
  echo "[*] Disabling hardware/ril"
  mv hardware/ril hardware/ril.disabled 2>/dev/null
fi

# -----------------------------------
# 2. Patch hardware root makefile
# -----------------------------------
ROOTMK="hardware/Android.mk"
if [ -f "$ROOTMK" ]; then
  echo "[*] Patching hardware/Android.mk"
  cp "$ROOTMK" "$ROOTMK.bak"
  sed -i "/ril/d" "$ROOTMK"
fi

# -----------------------------------
# 3. Device tree cleanup ONLY (fast)
# -----------------------------------
DEVICE_DIR=$(find device -type d -name "*a5ltechn*" | head -n 1)

if [ -n "$DEVICE_DIR" ]; then
  echo "[*] Cleaning device tree refs"

  sed -i "/ril/d" "$DEVICE_DIR/device.mk" 2>/dev/null
  sed -i "/ril/d" "$DEVICE_DIR/BoardConfig.mk" 2>/dev/null
fi

# -----------------------------------
# 4. Clean build artifacts
# -----------------------------------
echo "[*] Cleaning old outputs"
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*
rm -rf out/target/product/*/obj/EXECUTABLES/rild*

echo ""
echo "[✓] RIL fully disabled (safe mode)"
echo "Now run:"
echo "  mka installclean"
echo "  mka bacon"
'
