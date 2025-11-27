#!/bin/bash
# Build script for box2d library for Web/Emscripten
# Usage: ./build-box2d-web.sh [build_type]
# Example: ./build-box2d-web.sh Release
# Example: ./build-box2d-web.sh Debug

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOX2D_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOKOL_CSHARP_ROOT="$(cd "$BOX2D_DIR/../.." && pwd)"

# Parse arguments
BUILD_TYPE="${1:-Release}"

# Set Emscripten version
EMSCRIPTEN_VERSION="3.1.34"

echo "=========================================="
echo "Building box2d for Web/Emscripten"
echo "Build Type: $BUILD_TYPE"
echo "Emscripten Version: $EMSCRIPTEN_VERSION"
echo "=========================================="

# Path to local emsdk
EMSDK_PATH="$SOKOL_CSHARP_ROOT/tools/emsdk/emsdk"

# Check if local emsdk exists
if [ -f "$EMSDK_PATH" ]; then
    echo "Using local emsdk from Sokol.NET..."
    
    # Make emsdk executable if it isn't already
    chmod +x "$EMSDK_PATH"
    
    # Activate Emscripten SDK with the specified version
    echo "Installing Emscripten SDK version $EMSCRIPTEN_VERSION..."
    "$EMSDK_PATH" install "$EMSCRIPTEN_VERSION"
    
    echo "Activating Emscripten SDK version $EMSCRIPTEN_VERSION..."
    "$EMSDK_PATH" activate "$EMSCRIPTEN_VERSION"
    
    # Set up environment variables for Emscripten
    echo "Setting up Emscripten environment..."
    source "$SOKOL_CSHARP_ROOT/tools/emsdk/emsdk_env.sh"
else
    echo "Local emsdk not found, using system emscripten (assuming CI environment)..."
    
    # Check if emcc is available
    if ! command -v emcc &> /dev/null; then
        echo "Error: emcc not found in PATH"
        echo "Please install Emscripten or run from Sokol.NET with emsdk submodule initialized"
        exit 1
    fi
    
    # Verify emscripten version
    EMCC_VERSION=$(emcc --version | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    echo "Found Emscripten version: $EMCC_VERSION"
    
    if [ "$EMCC_VERSION" != "$EMSCRIPTEN_VERSION" ]; then
        echo "Warning: Emscripten version mismatch (expected $EMSCRIPTEN_VERSION, found $EMCC_VERSION)"
        echo "Continuing anyway..."
    fi
fi

echo "Using Emscripten: $(emcc --version | head -n 1)"

# Create build directory
BUILD_DIR="$BOX2D_DIR/build-emscripten"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set BOX2D_VALIDATE based on build type
if [ "$BUILD_TYPE" = "Debug" ]; then
    VALIDATE_FLAG="ON"
else
    VALIDATE_FLAG="OFF"
fi

# Configure with CMake for Emscripten
echo "Configuring with CMake..."
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBOX2D_BUILD_UNIT_TESTS=OFF \
    -DBOX2D_BUILD_TESTBED=OFF \
    -DBOX2D_BUILD_DOCS=OFF \
    -DBOX2D_SAMPLES=OFF \
    -DBOX2D_VALIDATE="$VALIDATE_FLAG"

# Build
echo "Building..."
emmake make box2d -j$(nproc)

echo "=========================================="
echo "Build complete!"
echo "Output: $BUILD_DIR/src/libbox2d.a"
echo "=========================================="

# Verify the library was created
if [ -f "$BUILD_DIR/src/libbox2d.a" ]; then
    echo "✓ Successfully built libbox2d.a"
    ls -lh "$BUILD_DIR/src/libbox2d.a"
    
    # Copy to the expected location
    ARCH="x86"  # Emscripten is architecture-independent, but we use x86 for consistency
    if [ "$BUILD_TYPE" = "Debug" ]; then
        OUTPUT_DIR="$BOX2D_DIR/libs/emscripten/$ARCH/debug"
    else
        OUTPUT_DIR="$BOX2D_DIR/libs/emscripten/$ARCH/release"
    fi
    
    mkdir -p "$OUTPUT_DIR"
    cp "$BUILD_DIR/src/libbox2d.a" "$OUTPUT_DIR/box2d.a"
    echo "✓ Copied to $OUTPUT_DIR/box2d.a"
else
    echo "✗ Failed to build libbox2d.a"
    exit 1
fi

echo ""
echo "=========================================="
echo "Web/Emscripten build complete!"
echo "Output: $OUTPUT_DIR/box2d.a"
echo "=========================================="
