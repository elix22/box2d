#!/bin/bash
# Master build script for box2d library - builds for all platforms
# Usage: ./build-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Building box2d for all platforms"
echo "=========================================="

# Detect current platform
PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin*)
        echo "Running on macOS"
        
        # Build for macOS (both architectures)
        echo ""
        echo "Building for macOS (arm64)..."
        "$SCRIPT_DIR/build-box2d-macos.sh" arm64 Release
        
        echo ""
        echo "Building for macOS (x86_64)..."
        "$SCRIPT_DIR/build-box2d-macos.sh" x86_64 Release
        
        # Build for iOS if on macOS
        echo ""
        echo "Building for iOS (device)..."
        "$SCRIPT_DIR/build-box2d-ios.sh" iphoneos Release
        
        echo ""
        echo "Building for iOS (simulator)..."
        "$SCRIPT_DIR/build-box2d-ios.sh" iphonesimulator Release
        ;;
        
    Linux*)
        echo "Running on Linux"
        
        # Build for Linux
        echo ""
        echo "Building for Linux..."
        "$SCRIPT_DIR/build-box2d-linux.sh" Release
        ;;
        
    MINGW*|MSYS*|CYGWIN*)
        echo "Running on Windows"
        
        # Build for Windows (call PowerShell script)
        echo ""
        echo "Building for Windows (x64)..."
        pwsh "$SCRIPT_DIR/build-box2d-windows.ps1" -Architecture x64 -BuildType Release
        ;;
        
    *)
        echo "Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

# Build for Android (if NDK is available)
if [ ! -z "$ANDROID_NDK" ] || [ ! -z "$ANDROID_NDK_HOME" ]; then
    echo ""
    echo "Building for Android (all ABIs)..."
    "$SCRIPT_DIR/build-box2d-android-all.sh" Release
else
    echo ""
    echo "Skipping Android build (ANDROID_NDK not set)"
fi

# Build for Web/Emscripten
echo ""
echo "Building for Web/Emscripten..."
if "$SCRIPT_DIR/build-box2d-web.sh" Release 2>/dev/null; then
    echo "✓ Web build complete"
else
    echo "⚠ Web build skipped or failed (emsdk may not be available)"
fi

echo ""
echo "=========================================="
echo "All builds complete!"
echo "=========================================="
