#!/bin/bash
set -euo pipefail

# Build Wren as a static library for Odin bindings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building Wren static library ==="

echo "Applying local patches to Wren source..."
if [ -f patches/wren_compiler_readRawString.patch ]; then
  cd vendor/wren
  git apply --check ../patches/wren_compiler_readRawString.patch 2>/dev/null || echo "  Patch already applied"
  git apply ../patches/wren_compiler_readRawString.patch 2>/dev/null || true
  cd "$SCRIPT_DIR"
  echo "  -> Applied wren_compiler_readRawString.patch"
fi

# Step 1: Generate amalgamation
echo "Generating amalgamated source..."
mkdir -p vendor/wren/build
python3 vendor/wren/util/generate_amalgamation.py > vendor/wren/build/wren.c
echo "  -> vendor/wren/build/wren.c ($(wc -c < vendor/wren/build/wren.c) bytes)"

# Step 2: Compile to object file
echo "Compiling wren.c..."
cc -c -O2 -fPIC -I vendor/wren/src/include vendor/wren/build/wren.c -o vendor/wren/build/wren.o
echo "  -> vendor/wren/build/wren.o"

# Step 3: Archive to static library
echo "Creating static library..."
mkdir -p lib
ar rcs lib/libwren.a vendor/wren/build/wren.o
echo "  -> lib/libwren.a ($(wc -c < lib/libwren.a) bytes)"

# Step 4: Verify symbols (macOS prefixes with _)
echo ""
echo "Verifying symbols..."
SYMBOL_COUNT=$(nm lib/libwren.a 2>/dev/null | grep -cE " T _?wren[A-Z]" || true)
echo "  Found $SYMBOL_COUNT exported wren* symbols"

if [ "$SYMBOL_COUNT" -lt 30 ]; then
    echo "ERROR: Expected at least 30 wren symbols, found $SYMBOL_COUNT"
    exit 1
fi

echo ""
echo "=== Build complete ==="
