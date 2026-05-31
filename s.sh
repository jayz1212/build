#!/bin/bash

LOG=build_error.log
FIXLOG=removed_modules.log
COMPILED=compiled_removed.bp

> "$FIXLOG"
> "$COMPILED"

# ==============================
# Function: Remove module safely
# ==============================
remove_module_block() {
  local file="$1"
  local module="$2"

  awk -v mod="$module" -v logfile="$FIXLOG" -v compiled="$COMPILED" '
  BEGIN {
    in_block=0
    depth=0
    buffer=""
    keep=1
  }

  {
    line=$0

    # Detect start of cc module
    if (match(line, /^[[:space:]]*cc_[a-zA-Z0-9_]*[[:space:]]*{/)) {
      in_block=1
      depth=1
      buffer=line "\n"
      keep=1
      next
    }

    if (in_block) {
      buffer = buffer line "\n"

      # Track braces
      depth += gsub(/{/, "{")
      depth -= gsub(/}/, "}")

      # Check module name
      if (line ~ "name:[[:space:]]*\"" mod "\"") {
        keep=0
      }

      # End of block
      if (depth == 0) {
        if (keep) {
          printf "%s", buffer
        } else {
          # ✅ PRINT TO TERMINAL ONLY (stderr)
          printf "\n===== REMOVED MODULE: %s =====\n", mod > "/dev/stderr"
          printf "%s\n", buffer > "/dev/stderr"

          # ✅ Save raw log
          printf "\n===== REMOVED MODULE: %s (%s) =====\n%s\n", mod, FILENAME, buffer >> logfile

          # ✅ Save clean compiled block
          printf "%s\n\n", buffer >> compiled
        }

        in_block=0
        buffer=""
      }
      next
    }

    # Outside any module
    print line
  }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# ==============================
# Main loop
# ==============================
ITER=1

while true; do
  echo ""
  echo "=============================="
  echo "🔁 ITERATION $ITER"
  echo "=============================="

  source build/envsetup.sh
  lunch lineage_blossom-bp4a-eng

  # Run build
  m evolution 2>&1 | tee "$LOG"

  echo "===== PARSING ERRORS ====="

  MODULES=$(grep -oP 'system\(\K[^)]+' "$LOG" | sort -u)

  if [ -z "$MODULES" ]; then
    echo "✅ NO MORE PARTITION ERRORS!"
    break
  fi

  echo "⚠️ Modules to remove:"
  echo "$MODULES"

  FIXED=0

  for mod in $MODULES; do
    echo "🗑 Removing $mod"

    FILES=$(rg -l "name: \"$mod\"" vendor/)

    if [ -z "$FILES" ]; then
      echo "   ⚠️ Not found in vendor"
      continue
    fi

    for f in $FILES; do
      remove_module_block "$f" "$mod"
      echo "ITER $ITER: $mod -> $f" >> "$FIXLOG"
      FIXED=1
    done
  done

  if [ "$FIXED" -eq 0 ]; then
    echo "❌ Nothing fixed — stopping"
    break
  fi

  echo "🧹 Cleaning soong..."
  rm -rf out/soong

  ITER=$((ITER+1))
done

echo ""
echo "🎉 DONE!"
echo "📄 Full log: $FIXLOG"
echo "📦 Compiled modules: $COMPILED"
