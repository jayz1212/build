#!/bin/bash

LOG=build_error.log

# Outputs
DUP_LOG=duplicate_modules.txt
DUP_ANALYSIS=duplicate_analysis.txt
CHANGE_LOG=resolver_changes.log

> "$DUP_LOG"
> "$DUP_ANALYSIS"
> "$CHANGE_LOG"

# ==============================
# RULES
# ==============================
REMOVE_REGEX="codec2|stagefright|bufferpool|omx|sfplugin|media|alsa|thermal"
KEEP_VENDOR_REGEX="keymaster|drm|gatekeeper|biometric|fingerprint"
ALIAS_REGEX="_vendor$"
SKIP_REGEX="camera|radio|ril"

# ==============================
# LOG FUNCTION
# ==============================
log_change() {
  local action="$1"
  local mod="$2"
  local file="$3"

  echo "[$(date +%H:%M:%S)] [ITER $ITER] $action | $mod | $file" | tee -a "$CHANGE_LOG"
}

# ==============================
# DEPENDENCY CHECK
# ==============================
depends_on_vendor() {
  local mod="$1"
  rg -q "shared_libs:.*\"$mod\"" vendor/ 2>/dev/null
}

# ==============================
# DISABLE AOSP MODULE
# ==============================
disable_aosp_safe() {
  local mod="$1"

  echo "🛡️ KEEP vendor, disable AOSP → $mod"

  rg -l "name: \"$mod\"" system/ hardware/ frameworks/ 2>/dev/null | while read f; do
    if ! sed -n "/name: \"$mod\"/,/}/p" "$f" | grep -q "enabled:"; then
      sed -i "/name: \"$mod\"/,/}/ s/{/{\n    enabled: false,/" "$f"
      log_change "KEEP_VENDOR (disable AOSP)" "$mod" "$f"
    fi
  done
}

# ==============================
# REMOVE MODULE
# ==============================
remove_module_block() {
  local file="$1"
  local module="$2"

  awk -v mod="$module" '
  BEGIN { in_block=0; depth=0; buffer=""; keep=1 }

  {
    line=$0

    if (match(line, /^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*{/)) {
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

      if (line ~ "name:[[:space:]]*\"" mod "\"") keep=0

      if (depth == 0) {
        if (keep) printf "%s", buffer
        else printf "REMOVED: %s\n", mod > "/dev/stderr"

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
# ALIAS MODULE
# ==============================
alias_module() {
  local file="$1"
  local mod="$2"

  base=$(echo "$mod" | sed 's/_vendor$//')

  remove_module_block "$file" "$mod"

  cat <<EOF >> "$file"

cc_library_shared {
    name: "$mod",
    vendor: true,
    shared_libs: ["$base"],
}
EOF

  log_change "ALIAS → $base" "$mod" "$file"
}

# ==============================
# ANALYZE MODULE
# ==============================
analyze_module() {
  local mod="$1"

  if [[ "$mod" =~ $KEEP_VENDOR_REGEX ]]; then
    echo "KEEP VENDOR (disable AOSP)"
  elif [[ "$mod" =~ $REMOVE_REGEX ]]; then
    echo "KEEP AOSP (remove vendor)"
  elif [[ "$mod" =~ $ALIAS_REGEX ]]; then
    echo "ALIAS (vendor → AOSP)"
  else
    echo "UNKNOWN"
  fi
}

# ==============================
# MAIN LOOP
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

  # ==========================
  # Capture duplicates
  # ==========================
  grep 'found in multiple namespaces' "$LOG" | while read line; do
    mod=$(echo "$line" | grep -oP 'module "\K[^"]+')
    echo "$mod" >> "$DUP_LOG"
  done

  if [ -z "$MODULES" ]; then
    echo "✅ NO MORE ERRORS!"
    break
  fi

  FIXED=0

  for mod in $MODULES; do
    echo "🔎 Processing $mod"

    # SKIP
    if [[ "$mod" =~ $SKIP_REGEX ]]; then
      log_change "SKIP" "$mod" "-"
      continue
    fi

    # Dependency-aware keep vendor
    if depends_on_vendor "$mod"; then
      disable_aosp_safe "$mod"
      FIXED=1
      continue
    fi

    # KEEP vendor for critical
    if [[ "$mod" =~ $KEEP_VENDOR_REGEX ]]; then
      disable_aosp_safe "$mod"
      FIXED=1
      continue
    fi

    # ALIAS
    if [[ "$mod" =~ $ALIAS_REGEX ]]; then
      rg -l "name: \"$mod\"" vendor/ | while read f; do
        alias_module "$f" "$mod"
      done
      FIXED=1
      continue
    fi

    # REMOVE
    if [[ "$mod" =~ $REMOVE_REGEX ]]; then
      rg -l "name: \"$mod\"" vendor/ | while read f; do
        remove_module_block "$f" "$mod"
        log_change "REMOVE" "$mod" "$f"
      done
      FIXED=1
      continue
    fi

    log_change "UNKNOWN" "$mod" "-"
  done

  [ "$FIXED" -eq 0 ] && break

  echo "🧹 Cleaning soong..."
  rm -rf out/soong

  ITER=$((ITER+1))
done

# ==============================
# FINAL ANALYSIS
# ==============================
echo ""
echo "📊 ===== DUPLICATE MODULE ANALYSIS ====="

sort -u "$DUP_LOG" > "$DUP_LOG.tmp"
mv "$DUP_LOG.tmp" "$DUP_LOG"

while read mod; do
  action=$(analyze_module "$mod")
  printf "%-55s → %s\n" "$mod" "$action" | tee -a "$DUP_ANALYSIS"
done < "$DUP_LOG"

# ==============================
# FINAL CHANGE LOG OUTPUT
# ==============================
echo ""
echo "📜 ===== FULL CHANGE LOG ====="
cat "$CHANGE_LOG"

echo ""
echo "📄 Raw duplicates : $DUP_LOG"
echo "📄 Analysis       : $DUP_ANALYSIS"
echo "📄 Changes log    : $CHANGE_LOG"
echo "🎉 DONE"
