set -euo pipefail

FILES=(
  "device/xiaomi/blossom/blossom_vendor.mk"
  "device/xiaomi/blossom/device.mk"
)

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "skip: $f (not found)"
    continue
  fi

  cp -a "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

  # Delete the specific PRODUCT_BOOT_JARS block that lists the mediatek-* jars
  awk '
    # If we hit PRODUCT_BOOT_JARS and the following continued lines contain mediatek-*, drop that whole continued block.
    /^PRODUCT_BOOT_JARS[[:space:]]*\+=[[:space:]]*\\[[:space:]]*$/ {
      buf = $0 ORS
      has_mtk = 0
      while ((getline line) > 0) {
        buf = buf line ORS
        if (line ~ /mediatek-(common|framework|ims-base|ims-common|telecom-common|telephony-base|telephony-common)/) has_mtk = 1
        # continuation ends when the next line does NOT end with a backslash
        if (line !~ /\\[[:space:]]*$/) break
      }
      if (!has_mtk) {
        printf "%s", buf
      } else {
        print "# Removed: MTK jars must not be in PRODUCT_BOOT_JARS (bootclasspath allowlist enforcement)"
      }
      next
    }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

  echo "patched: $f"
done

echo
echo "Verify there are no remaining mediatek boot jars:"
rg -n "PRODUCT_BOOT_JARS|mediatek-(common|framework|ims-base|ims-common|telecom-common|telephony-base|telephony-common)" \
  device/xiaomi/blossom || true
