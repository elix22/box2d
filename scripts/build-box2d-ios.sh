#!/bin/bash
# Build script for box2d framework on iOS
# Usage: ./build-box2d-ios.sh [architecture] [build_type]
# Example: ./build-box2d-ios.sh arm64 Release
# Example: ./build-box2d-ios.sh x86_64 Debug (for simulator)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOX2D_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$BOX2D_DIR/build-xcode-ios"

# Parse arguments
ARCH="${1:-arm64}"
BUILD_TYPE="${2:-Release}"

echo "=========================================="
echo "Building box2d framework for iOS"
echo "Architecture: $ARCH"
echo "Build Type: $BUILD_TYPE"
echo "=========================================="

# Check if box2d directory exists
if [ ! -d "$BOX2D_DIR" ]; then
    echo "Error: box2d directory not found at $BOX2D_DIR"
    exit 1
fi

# Create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Determine SDK and deployment target based on architecture
if [ "$ARCH" = "arm64" ]; then
    SDK="iphoneos"
    DEPLOYMENT_TARGET="13.0"
else
    SDK="iphonesimulator"
    DEPLOYMENT_TARGET="13.0"
fi

# Set BOX2D_VALIDATE based on build type
if [ "$BUILD_TYPE" = "Debug" ]; then
    VALIDATE_FLAG="ON"
else
    VALIDATE_FLAG="OFF"
fi

# Configure with CMake for iOS
cmake .. \
    -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DBOX2D_BUILD_UNIT_TESTS=OFF \
    -DBOX2D_BUILD_TESTBED=OFF \
    -DBOX2D_BUILD_DOCS=OFF \
    -DBOX2D_SAMPLES=OFF \
    -DBOX2D_VALIDATE="$VALIDATE_FLAG"

# Build
cmake --build . --config "$BUILD_TYPE" --target box2d

# Create destination directory
DEST_DIR="$BOX2D_DIR/libs/ios/$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"
mkdir -p "$DEST_DIR"

# Copy framework to destination
echo "Copying framework to $DEST_DIR..."
FRAMEWORK_PATH="$BUILD_DIR/bin/$BUILD_TYPE/box2d.framework"
DEST_FRAMEWORK="$DEST_DIR/box2d.framework"

if [ -d "$FRAMEWORK_PATH" ]; then
    rm -rf "$DEST_FRAMEWORK"
    cp -R "$FRAMEWORK_PATH" "$DEST_FRAMEWORK"
else
    echo "Error: Framework not found at $FRAMEWORK_PATH"
    echo "Available files in build directory:"
    find "$BUILD_DIR" -name "*.framework" -type d 2>/dev/null || echo "No .framework directories found"
    find "$BUILD_DIR" -name "box2d*" -type f 2>/dev/null || echo "No box2d files found"
    exit 1
fi

echo "=========================================="
echo "Build complete!"
echo "Output: $DEST_DIR"
echo "=========================================="

# Verify the framework was created
if [ -d "$DEST_FRAMEWORK" ]; then
    echo "✓ Successfully built box2d framework"
    ls -lah "$DEST_FRAMEWORK"
    
    # Show framework info
    echo ""
    echo "Framework info:"
    if [ -f "$DEST_FRAMEWORK/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$DEST_FRAMEWORK/Info.plist" 2>/dev/null || echo "Could not read bundle identifier"
        /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$DEST_FRAMEWORK/Info.plist" 2>/dev/null || echo "Could not read bundle version"
    fi
    
    # Check if the binary exists
    if [ -f "$DEST_FRAMEWORK/box2d" ]; then
        file "$DEST_FRAMEWORK/box2d"
    else
        echo "Warning: Framework binary not found"
    fi
else
    echo "✗ Failed to build box2d framework"
    exit 1
fi
