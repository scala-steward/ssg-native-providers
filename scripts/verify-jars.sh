#!/usr/bin/env bash
# Verifies that packaged JARs contain the expected native artifacts.
#
# Run after `sbt packageBin` to validate JAR contents.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0

check_jar() {
  local jar="$1"
  shift
  local expected=("$@")

  if [ ! -f "$jar" ]; then
    echo "FAIL: JAR not found: $jar"
    ERRORS=$((ERRORS + 1))
    return
  fi

  local contents
  contents=$(jar tf "$jar")

  for entry in "${expected[@]}"; do
    if echo "$contents" | grep -q "$entry"; then
      echo "  OK: $entry"
    else
      echo "  MISSING: $entry in $jar"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

echo "=== Verifying sn-provider-tree-sitter ==="
SN_JAR=$(find "$ROOT_DIR/providers/sn-provider-tree-sitter/target" -name '*.jar' -not -name '*-sources*' -not -name '*-javadoc*' 2>/dev/null | head -1)
if [ -n "$SN_JAR" ]; then
  check_jar "$SN_JAR" \
    "native/linux-x86_64/libtree_sitter_all.a" \
    "native/linux-aarch64/libtree_sitter_all.a" \
    "native/macos-x86_64/libtree_sitter_all.a" \
    "native/macos-aarch64/libtree_sitter_all.a" \
    "native/windows-x86_64/tree_sitter_all.lib" \
    "native/windows-aarch64/tree_sitter_all.lib" \
    "sn-provider.json"
else
  echo "SKIP: sn-provider-tree-sitter JAR not found (run sbt packageBin first)"
fi

echo ""
echo "=== Verifying pnm-provider-tree-sitter-desktop ==="
PNM_JAR=$(find "$ROOT_DIR/providers/pnm-provider-tree-sitter-desktop/target" -name '*.jar' -not -name '*-sources*' -not -name '*-javadoc*' 2>/dev/null | head -1)
if [ -n "$PNM_JAR" ]; then
  check_jar "$PNM_JAR" \
    "native/linux-x86_64/libtree_sitter_all.so" \
    "native/linux-aarch64/libtree_sitter_all.so" \
    "native/macos-x86_64/libtree_sitter_all.dylib" \
    "native/macos-aarch64/libtree_sitter_all.dylib" \
    "native/windows-x86_64/tree_sitter_all.dll" \
    "native/windows-aarch64/tree_sitter_all.dll" \
    "pnm-provider.json"
else
  echo "SKIP: pnm-provider-tree-sitter-desktop JAR not found (run sbt packageBin first)"
fi

echo ""
echo "=== Verifying wasm-provider-tree-sitter ==="
WASM_JAR=$(find "$ROOT_DIR/providers/wasm-provider-tree-sitter/target" -name '*.jar' -not -name '*-sources*' -not -name '*-javadoc*' 2>/dev/null | head -1)
if [ -n "$WASM_JAR" ]; then
  check_jar "$WASM_JAR" \
    "wasm/web-tree-sitter.js" \
    "wasm/web-tree-sitter.wasm" \
    "wasm/grammars/"
else
  echo "SKIP: wasm-provider-tree-sitter JAR not found (run sbt packageBin first)"
fi

echo ""
echo "=== Verifying tree-sitter-queries ==="
QUERIES_JAR=$(find "$ROOT_DIR/providers/tree-sitter-queries/target" -name '*.jar' -not -name '*-sources*' -not -name '*-javadoc*' 2>/dev/null | head -1)
if [ -n "$QUERIES_JAR" ]; then
  check_jar "$QUERIES_JAR" \
    "queries/rust/highlights.scm" \
    "queries/python/highlights.scm" \
    "queries/javascript/highlights.scm" \
    "queries/scala/highlights.scm"
else
  echo "SKIP: tree-sitter-queries JAR not found (run sbt packageBin first)"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS missing entries"
  exit 1
else
  echo "All verified entries present."
fi
