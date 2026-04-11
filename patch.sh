#!/usr/bin/env bash
set -e

echo "🔧 Starting Python compatibility fix..."

# 1. Install python2 if missing
if ! command -v python2 >/dev/null 2>&1; then
    echo "📦 Installing python2..."
    sudo apt update
    sudo apt install -y python2
fi

# 2. Force python2 in environment
echo "⚙️ Setting Python2 as default for build..."
export PYTHON=python2

# Some builds call 'python' directly → override locally
mkdir -p prebuilts/python-fix
cat > prebuilts/python-fix/python << 'EOF'
#!/usr/bin/env bash
exec python2 "$@"
EOF
chmod +x prebuilts/python-fix/python

export PATH="$(pwd)/prebuilts/python-fix:$PATH"

# 3. Fix known broken scripts safely (only simple print cases)
echo "🩹 Patching known Python scripts..."

PATCHED=0

fix_file() {
    FILE="$1"
    if [ -f "$FILE" ]; then
        if grep -q 'print "' "$FILE"; then
            echo "  ✔ Fixing $FILE"
            sed -i -E 's/print "(.*)"/print("\1")/g' "$FILE"
            PATCHED=$((PATCHED+1))
        fi
    fi
}

fix_file build/tools/check_radio_versions.py

# 4. Optional: Fix other common legacy scripts (safe subset)
find build/ -name "*.py" | while read -r f; do
    if grep -q 'print "' "$f"; then
        sed -i -E 's/print "(.*)"/print("\1")/g' "$f" || true
    fi
done

# 5. Clean conflicting python bytecode
echo "🧹 Cleaning old .pyc files..."
find . -name "*.pyc" -delete

echo "✅ Done! Python compatibility layer ready."
echo ""
echo "👉 Now run:"
echo "   source build/envsetup.sh"
echo "   lunch lineage_a5ltechn-eng"
echo "   make recoveryimage -j$(nproc)"
