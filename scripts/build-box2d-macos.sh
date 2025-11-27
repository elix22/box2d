#!/bin/bash
# Build script for box2d library on macOS
# Usage: ./build-box2d-macos.sh [architecture] [build_type]
# Example: ./build-box2d-macos.sh arm64 Release
# Example: ./build-box2d-macos.sh x86_64 Debug

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOX2D_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
ARCH="${1:-arm64}"
BUILD_TYPE="${2:-Release}"

# Normalize x86_64 to X64 for directory naming
if [ "$ARCH" = "x86_64" ]; then
    ARCH_DIR="X64"
else
    ARCH_DIR="$ARCH"
fi

BUILD_DIR="$BOX2D_DIR/build-xcode-macos-$ARCH"

echo "=========================================="
echo "Building box2d for macOS"
echo "Architecture: $ARCH"
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
    -G Xcode \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DBOX2D_BUILD_UNIT_TESTS=OFF \
    -DBOX2D_BUILD_TESTBED=OFF \
    -DBOX2D_BUILD_DOCS=OFF \
    -DBOX2D_SAMPLES=OFF \
    -DBOX2D_VALIDATE="$VALIDATE_FLAG"

# Build only the box2d library target (skip tests and samples)
cmake --build . --config "$BUILD_TYPE" --target box2d

echo "=========================================="
echo "Build complete!"
echo "Output: $BUILD_DIR/bin/$BUILD_TYPE/libbox2d.dylib"
echo "=========================================="

# Verify the library was created (versioned dylib)
DYLIB_PATH="$BUILD_DIR/bin/$BUILD_TYPE/libbox2d.3.2.0.dylib"
if [ -f "$DYLIB_PATH" ]; then
    echo "✓ Successfully built libbox2d.3.2.0.dylib"
    file "$DYLIB_PATH"
    
    # Copy to the expected location
    if [ "$BUILD_TYPE" = "Debug" ]; then
        OUTPUT_DIR="$BOX2D_DIR/libs/macos/$ARCH_DIR/debug"
    else
        OUTPUT_DIR="$BOX2D_DIR/libs/macos/$ARCH_DIR/release"
    fi
    
    mkdir -p "$OUTPUT_DIR"
    # Copy versioned library
    cp "$DYLIB_PATH" "$OUTPUT_DIR/"
    
    # Create symlink
    ln -sf libbox2d.3.2.0.dylib "$OUTPUT_DIR/libbox2d.dylib"
    
    # Fix install names and code sign
    echo "Fixing install names and signing libraries..."
    install_name_tool -id "@loader_path/libbox2d.3.2.0.dylib" "$OUTPUT_DIR/libbox2d.3.2.0.dylib"
    
    # Strip and re-sign to ensure unique signature
    codesign --remove-signature "$OUTPUT_DIR/libbox2d.3.2.0.dylib" 2>/dev/null || true
    
    # Add timestamp to identifier to make each build unique
    TIMESTAMP=$(date +%s)
    codesign --force --sign - --identifier "libbox2d.${TIMESTAMP}" "$OUTPUT_DIR/libbox2d.3.2.0.dylib"
    
    echo "✓ Copied to $OUTPUT_DIR/libbox2d.3.2.0.dylib"
    echo "✓ Created symlink $OUTPUT_DIR/libbox2d.dylib"
    echo "✓ Signed library with identifier libbox2d.${TIMESTAMP}"
else
    echo "✗ Failed to build libbox2d.dylib"
    exit 1
fi
