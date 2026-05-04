#!/usr/bin/env bash
# Downloads tree-sitter-natives release artifacts and unpacks them into native/.
#
# Usage:
#   scripts/download-release.sh <version>
#   scripts/download-release.sh v0.1.0
#
# Requires: curl, tar, unzip

set -euo pipefail

VERSION="${1:?Usage: download-release.sh <version>}"
REPO="kubuszok/tree-sitter-natives"
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NATIVE_DIR="$ROOT_DIR/native"

echo "=== Downloading tree-sitter-natives ${VERSION} ==="

# Clean previous downloads
rm -rf "$NATIVE_DIR"
mkdir -p "$NATIVE_DIR/cross" "$NATIVE_DIR/wasm" "$NATIVE_DIR/queries"

# Desktop platforms (tar.gz for Linux/macOS, zip for Windows)
for plat in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64; do
  echo "--- Downloading tree-sitter-${plat}.tar.gz"
  mkdir -p "$NATIVE_DIR/cross/${plat}"
  curl -fSL "${BASE_URL}/tree-sitter-${plat}.tar.gz" | tar xz -C "$NATIVE_DIR/cross/${plat}"
done

for plat in windows-x86_64 windows-aarch64; do
  echo "--- Downloading tree-sitter-${plat}.zip"
  mkdir -p "$NATIVE_DIR/cross/${plat}"
  TMPZIP=$(mktemp)
  curl -fSL "${BASE_URL}/tree-sitter-${plat}.zip" -o "$TMPZIP"
  unzip -qo "$TMPZIP" -d "$NATIVE_DIR/cross/${plat}"
  rm -f "$TMPZIP"
done

# WASM
echo "--- Downloading tree-sitter-wasm.tar.gz"
curl -fSL "${BASE_URL}/tree-sitter-wasm.tar.gz" | tar xz -C "$NATIVE_DIR/wasm"

# Queries
echo "--- Downloading tree-sitter-queries.tar.gz"
curl -fSL "${BASE_URL}/tree-sitter-queries.tar.gz" | tar xz -C "$NATIVE_DIR/queries"

echo ""
echo "=== Download complete ==="
echo "Desktop artifacts: $NATIVE_DIR/cross/"
echo "WASM artifacts:    $NATIVE_DIR/wasm/"
echo "Query files:       $NATIVE_DIR/queries/"

# Quick verification
echo ""
echo "--- Artifact verification ---"
for plat in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64 windows-x86_64 windows-aarch64; do
  count=$(find "$NATIVE_DIR/cross/${plat}" -type f | wc -l | tr -d ' ')
  echo "  ${plat}: ${count} files"
done
wasm_count=$(find "$NATIVE_DIR/wasm" -name '*.wasm' -type f | wc -l | tr -d ' ')
echo "  wasm: ${wasm_count} .wasm files"
query_count=$(find "$NATIVE_DIR/queries" -name '*.scm' -type f | wc -l | tr -d ' ')
echo "  queries: ${query_count} .scm files"
