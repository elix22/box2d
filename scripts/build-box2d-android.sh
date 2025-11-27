#!/bin/bash
# Build script for box2d library for Android
# Usage: ./build-box2d-android.sh [abi] [build_type]
# Example: ./build-box2d-android.sh arm64-v8a Release
# Example: ./build-box2d-android.sh armeabi-v7a Debug
# Supported ABIs: arm64-v8a, armeabi-v7a, x86, x86_64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOX2D_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
ANDROID_ABI="${1:-arm64-v8a}"
BUILD_TYPE="${2:-Release}"
BUILD_DIR="$BOX2D_DIR/build-android-$ANDROID_ABI"

echo "=========================================="
echo "Building box2d for Android"
echo "ABI: $ANDROID_ABI"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Check for Android NDK
if [ -z "$ANDROID_NDK" ]; then
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "Error: ANDROID_NDK or ANDROID_NDK_HOME environment variable not set"
        echo "Please set one of these to your Android NDK path"
        exit 1
    fi
    ANDROID_NDK="$ANDROID_NDK_HOME"
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo "Error: Android NDK not found at: $ANDROID_NDK"
    exit 1
fi

echo "Using Android NDK: $ANDROID_NDK"

# Determine API level
ANDROID_NATIVE_API_LEVEL="${ANDROID_NATIVE_API_LEVEL:-21}"
echo "API Level: $ANDROID_NATIVE_API_LEVEL"

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
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$ANDROID_ABI" \
    -DANDROID_NATIVE_API_LEVEL="$ANDROID_NATIVE_API_LEVEL" \
    -DANDROID_STL=c++_shared \
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
    echo "✓ Successfully built libbox2d.so for $ANDROID_ABI"
    ls -lh "$BUILD_DIR/bin/libbox2d.so"
    
    # Copy to the expected location
    if [ "$BUILD_TYPE" = "Debug" ]; then
        OUTPUT_DIR="$BOX2D_DIR/libs/android/$ANDROID_ABI/debug"
    else
        OUTPUT_DIR="$BOX2D_DIR/libs/android/$ANDROID_ABI/release"
    fi
    
    mkdir -p "$OUTPUT_DIR"
    cp "$BUILD_DIR/bin/libbox2d.so" "$OUTPUT_DIR/"
    echo "✓ Copied to $OUTPUT_DIR/libbox2d.so"
else
    echo "✗ Failed to build libbox2d.so"
    exit 1
fi
