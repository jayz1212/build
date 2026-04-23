#!/bin/bash

LOG=build_error.log
FIXLOG=removed_modules.log
COMPILED=compiled_removed.bp

> "$FIXLOG"
> "$COMPILED"

# ==============================
# Whitelist patterns (NEVER DELETE)
# ==============================
WHITELIST_REGEX="camera|drm|keymaster|gatekeeper|keystore|widevine|fingerprint|biometric|radio|ril"

# ==============================
# Function: Remove module safely
# ==============================
remove_module_block() {
  local file="$1"
  local module="$2"

  awk -v mod="$module" -v logfile="$FIXLOG" -v compiled="$COMPILED" '
  BEGIN { in_block=0; depth=0; buffer=""; keep=1 }

  {
    line=$0

    if (match(line, /^[[:space:]]*cc_[a-zA-Z0-9_]*[[:space:]]*{/)) {
      in_block=1
      depth=1
      buffer=line "\n"
      keep=1
      next
    }

    if (in_block) {
      buffer = buffer line "\n"
      depth += gsub(/{/, "{")
      depth -= gsub(/}/, "}")

      if (line ~ "name:[[:space:]]*\"" mod "\"") {
        keep=0
      }

      if (depth == 0) {
        if (keep) {
          printf "%s", buffer
        } else {
          printf "\n===== REMOVED MODULE: %s =====\n", mod > "/dev/stderr"
          printf "%s\n", buffer > "/dev/stderr"

          printf "\n===== REMOVED MODULE: %s (%s) =====\n%s\n", mod, FILENAME, buffer >> logfile
          printf "%s\n\n", buffer >> compiled
        }

        in_block=0
        buffer=""
      }
      next
    }

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

  m evolution 2>&1 | tee "$LOG"

  echo "===== PARSING ERRORS ====="

  MODULES=$( (
    grep -oP 'system\(\K[^)]+' "$LOG"
    grep -oP 'module "\K[^"]+' "$LOG"
  ) | sort -u )

  if [ -z "$MODULES" ]; then
    echo "✅ NO MORE ERRORS!"
    break
  fi

  echo "⚠️ Modules detected:"
  echo "$MODULES"

  FIXED=0

  for mod in $MODULES; do
    echo "🔎 Processing $mod"

    # 🛡️ WHITELIST CHECK
    if [[ "$mod" =~ $WHITELIST_REGEX ]]; then
      echo "🛡️ Skipping protected module: $mod"
      continue
    fi

    FILES=$(rg -l "name: \"$mod\"" vendor/)

    if [ -z "$FILES" ]; then
      echo "   ℹ️ Not in vendor → skipping"
      continue
    fi

    for f in $FILES; do
      if [[ "$f" == vendor/xiaomi/blossom/* ]]; then
        echo "🗑 Removing (vendor duplicate): $mod from $f"

        remove_module_block "$f" "$mod"
        echo "ITER $ITER: $mod -> $f (REMOVED)" >> "$FIXLOG"

        FIXED=1
      else
        echo "   ✅ Keeping (non-vendor): $f"
      fi
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
echo "📄 Log: $FIXLOG"
echo "📦 Compiled removed modules: $COMPILED"
