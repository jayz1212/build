#!/bin/bash
set -e

LOG=build_error.log
FIXLOG=fixed_modules.log

> "$FIXLOG"

while true; do
  echo "===== BUILD START ====="

  source build/envsetup.sh
  lunch lineage_blossom-bp4a-eng

  # Run build and capture errors
  m evolution 2>&1 | tee "$LOG" || true

  echo "===== PARSING ERRORS ====="

  # Extract module names from partition mismatch errors
  MODULES=$(grep -oP 'system\(\K[^)]+' "$LOG" | sort -u)

  if [ -z "$MODULES" ]; then
    echo "✅ No more partition errors!"
    break
  fi

  echo "Found modules:"
  echo "$MODULES"

  # Apply fixes (ONLY disable, no prefer changes)
  for mod in $MODULES; do
    echo "🔧 Fixing $mod"

    rg -l "name: \"$mod\"" vendor/ | while IFS= read -r f; do
      # Disable the module block if not already disabled
      sed -i "/name: \"$mod\"/,/}/ {
        /enabled:/! s/{/{\n    enabled: false,/
      }" "$f"

      echo "$mod -> $f" >> "$FIXLOG"
    done
  done

  echo "===== CLEANING ====="
  rm -rf out/soong

done

echo "🎉 Build fixed!"
echo "Changed modules saved in: $FIXLOG"
