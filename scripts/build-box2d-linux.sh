#!/bin/bash
# Build script for box2d library on Linux
# Usage: ./build-box2d-linux.sh [build_type]
# Example: ./build-box2d-linux.sh Release
# Example: ./build-box2d-linux.sh Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOX2D_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$BOX2D_DIR/build-linux"

# Parse arguments - default to Release
BUILD_TYPE="${1:-Release}"

echo "=========================================="
echo "Building box2d for Linux"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set BOX2D_VALIDATE based on build type
if [ "$BUILD_TYPE" = "Debug" ]; then
    VALIDATE_FLAG="ON"
else
    VALIDATE_FLAG="OFF"
fi

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBOX2D_BUILD_UNIT_TESTS=OFF \
    -DBOX2D_BUILD_TESTBED=OFF \
    -DBOX2D_BUILD_DOCS=OFF \
    -DBOX2D_SAMPLES=OFF \
    -DBOX2D_VALIDATE="$VALIDATE_FLAG"

# Build
cmake --build . --config "$BUILD_TYPE" --target box2d -- -j$(nproc)

echo "=========================================="
echo "Build complete!"
echo "Output: $BUILD_DIR/bin/libbox2d.so"
echo "=========================================="

# Verify the library was created
if [ -f "$BUILD_DIR/bin/libbox2d.so" ]; then
    echo "✓ Successfully built libbox2d.so"
    file "$BUILD_DIR/bin/libbox2d.so"
    
    # Copy to the expected location
    ARCH="X64"  # Use X64 instead of x86_64 to match .NET expectations
    if [ "$BUILD_TYPE" = "Debug" ]; then
        OUTPUT_DIR="$BOX2D_DIR/libs/linux/$ARCH/debug"
    else
        OUTPUT_DIR="$BOX2D_DIR/libs/linux/$ARCH/release"
    fi
    
    mkdir -p "$OUTPUT_DIR"
    cp "$BUILD_DIR/bin/libbox2d.so" "$OUTPUT_DIR/"
    echo "✓ Copied to $OUTPUT_DIR/libbox2d.so"
else
    echo "✗ Failed to build libbox2d.so"
    exit 1
fi
