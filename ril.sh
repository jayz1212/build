bash -c '
echo "[*] Fixing duplicate RIL modules (Soong)..."

# Remove BOTH versions safely
rm -rf hardware/ril
rm -rf hardware/ril.disabled

echo "[*] Removing any leftover Soong cache"
rm -rf out/soong

echo "[✓] Cleaned duplicate RIL modules"
echo "Now rebuild:"
echo "  mka installclean"
echo "  mka bacon"
'
