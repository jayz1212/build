#!/bin/bash

LOG=build_error.log
FIXLOG=fixed_modules.log

> "$FIXLOG"

ITER=1

while true; do
  echo ""
  echo "=============================="
  echo "🔁 ITERATION $ITER"
  echo "=============================="

  source build/envsetup.sh
  lunch lineage_blossom-bp4a-eng

  # Run build and capture errors (DO NOT EXIT ON FAILURE)
  m evolution 2>&1 | tee "$LOG"

  echo "===== PARSING ERRORS ====="

  # Extract ONLY partition mismatch modules
  MODULES=$(grep -oP 'system\(\K[^)]+' "$LOG" | sort -u)

  if [ -z "$MODULES" ]; then
    echo "✅ NO MORE PARTITION ERRORS!"
    break
  fi

  echo "⚠️ Found conflicting modules:"
  echo "$MODULES"

  FIXED_THIS_ROUND=0

  for mod in $MODULES; do
    echo "🔧 Fixing $mod"

    MATCHES=$(rg -l "name: \"$mod\"" vendor/)

    if [ -z "$MATCHES" ]; then
      echo "   ⚠️ Not found in vendor (skipped)"
      continue
    fi

    echo "$MATCHES" | while IFS= read -r f; do
      # Only add enabled:false if not already present
      sed -i "/name: \"$mod\"/,/}/ {
        /enabled:/! s/{/{\n    enabled: false,/
      }" "$f"

      echo "ITER $ITER: $mod -> $f" >> "$FIXLOG"
    done

    FIXED_THIS_ROUND=1
  done

  if [ "$FIXED_THIS_ROUND" -eq 0 ]; then
    echo "❌ No fixes applied this round — stopping to avoid infinite loop"
    break
  fi

  echo "🧹 Cleaning soong..."
  rm -rf out/soong

  ITER=$((ITER+1))
done

echo ""
echo "🎉 DONE!"
echo "📄 Fix log: $FIXLOG"
