#!/usr/bin/env bash
# Builds release artifacts with Dart obfuscation + split debug symbols.
#
# Symbols are written to build/symbols/ and MUST be archived alongside the
# build if you want to de-obfuscate crash reports. The directory is
# gitignored (symbolication happens off-repo).
#
# Usage:
#   scripts/build_release.sh apk        # single-arch APK
#   scripts/build_release.sh appbundle  # AAB for Play Store
#   scripts/build_release.sh ios        # iOS archive prep (no signing)
#
# Android requires android/key.properties — see key.properties.example.

set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-apk}"
SYMBOLS_DIR="build/symbols"
mkdir -p "$SYMBOLS_DIR"

case "$TARGET" in
  apk)
    flutter build apk --release \
      --obfuscate \
      --split-debug-info="$SYMBOLS_DIR"
    ;;
  appbundle)
    flutter build appbundle --release \
      --obfuscate \
      --split-debug-info="$SYMBOLS_DIR"
    ;;
  ios)
    flutter build ios --release \
      --obfuscate \
      --split-debug-info="$SYMBOLS_DIR" \
      --no-codesign
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    echo "Usage: $0 {apk|appbundle|ios}" >&2
    exit 1
    ;;
esac

echo
echo "Build complete."
echo "Debug symbols: $SYMBOLS_DIR"
echo "Archive $SYMBOLS_DIR alongside the build — required to symbolicate crash reports."
