bash -c '
echo "====================================="
echo "[*] FINAL RIL REMOVAL (AOSP + SAMSUNG)"
echo "====================================="

# -----------------------------------
# 1. Remove hardware/ril entirely
# -----------------------------------
if [ -d "hardware/ril" ]; then
  echo "[*] Removing AOSP RIL (hardware/ril)"
  mv hardware/ril hardware/ril.disabled 2>/dev/null
fi

# -----------------------------------
# 2. Patch root Android.mk if needed
# -----------------------------------
ROOTMK="hardware/Android.mk"
if [ -f "$ROOTMK" ]; then
  echo "[*] Patching hardware/Android.mk"

  cp "$ROOTMK" "$ROOTMK.bak"

  sed -i "/ril/d" "$ROOTMK"
fi

# -----------------------------------
# 3. Clean any leftover references
# -----------------------------------
echo "[*] Removing any leftover RIL references in build system"
grep -rl "reference-ril" . | xargs -r sed -i "/reference-ril/d"
grep -rl "rild" . | xargs -r sed -i "/rild/d"
grep -rl "libril" . | xargs -r sed -i "/libril/d"

# -----------------------------------
# 4. Clean build artifacts
# -----------------------------------
echo "[*] Cleaning old outputs"
rm -rf out/target/product/*/obj/SHARED_LIBRARIES/*ril*
rm -rf out/target/product/*/obj/EXECUTABLES/rild*

echo ""
echo "[✓] ALL RIL (Samsung + AOSP) REMOVED"
echo "Now rebuild:"
echo "  mka installclean"
echo "  mka bacon"
'
