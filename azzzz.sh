#!/bin/bash

LOG=build_error.log
FIXLOG=removed_modules.log

> "$FIXLOG"

ITER=1

while true; do
  echo ""
  echo "=============================="
  echo "🔁 ITERATION $ITER"
  echo "=============================="

  source build/envsetup.sh
  lunch lineage_blossom-bp4a-eng

  # Build (allow failure)
  m evolution 2>&1 | tee "$LOG"

  echo "===== PARSING ERRORS ====="

  MODULES=$(grep -oP 'system\(\K[^)]+' "$LOG" | sort -u)

  if [ -z "$MODULES" ]; then
    echo "✅ NO MORE PARTITION ERRORS!"
    break
  fi

  echo "⚠️ Found conflicting modules:"
  echo "$MODULES"

  FIXED_THIS_ROUND=0

  for mod in $MODULES; do
    echo "🗑️ Removing module $mod"

    MATCHES=$(rg -l "name: \"$mod\"" vendor/)

    if [ -z "$MATCHES" ]; then
      echo "   ⚠️ Not found in vendor (skipped)"
      continue
    fi

    echo "$MATCHES" | while IFS= read -r f; do
      # 🔥 Delete entire module block
      sed -i "/name: \"$mod\"/,/}/d" "$f"

      echo "ITER $ITER: $mod -> $f (REMOVED)" >> "$FIXLOG"
    done

    FIXED_THIS_ROUND=1
  done

  if [ "$FIXED_THIS_ROUND" -eq 0 ]; then
    echo "❌ No fixes applied — stopping"
    break
  fi

  echo "🧹 Cleaning soong..."
  rm -rf out/soong

  ITER=$((ITER+1))
done

echo ""
echo "🎉 DONE!"
echo "📄 Removed modules log: $FIXLOG"
