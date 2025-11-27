#!/bin/bash
# Build script for multiple Android ABIs
# Usage: ./build-box2d-android-all.sh [build_type]
# Example: ./build-box2d-android-all.sh Release
# Example: ./build-box2d-android-all.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${1:-Release}"

echo "=========================================="
echo "Building box2d for all Android ABIs"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Build for all common ABIs
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo ""
    echo "Building for $ABI..."
    "$SCRIPT_DIR/build-box2d-android.sh" "$ABI" "$BUILD_TYPE"
done

echo ""
echo "=========================================="
echo "All Android builds complete!"
echo "=========================================="
