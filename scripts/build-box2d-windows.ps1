# Build script for box2d library on Windows
# Usage: .\build-box2d-windows.ps1 [-Architecture <arch>] [-BuildType <type>]
# Example: .\build-box2d-windows.ps1 -Architecture x64 -BuildType Release
# Example: .\build-box2d-windows.ps1 -Architecture Win32 -BuildType Debug
# Architectures: x64, Win32, ARM64

param(
    [string]$Architecture = "x64",
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Box2DDir = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $Box2DDir "build-windows-$Architecture"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building box2d for Windows" -ForegroundColor Cyan
Write-Host "Architecture: $Architecture" -ForegroundColor Cyan
Write-Host "Build Type: $BuildType" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Create build directory
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Set-Location $BuildDir

# Set BOX2D_VALIDATE based on build type
if ($BuildType -eq "Debug") {
    $ValidateFlag = "ON"
} else {
    $ValidateFlag = "OFF"
}

# Configure with CMake
Write-Host "Configuring CMake..." -ForegroundColor Yellow
cmake .. `
    -G "Visual Studio 17 2022" `
    -A $Architecture `
    -DCMAKE_BUILD_TYPE="$BuildType" `
    -DBOX2D_BUILD_UNIT_TESTS=OFF `
    -DBOX2D_BUILD_TESTBED=OFF `
    -DBOX2D_BUILD_DOCS=OFF `
    -DBOX2D_SAMPLES=OFF `
    -DBOX2D_VALIDATE="$ValidateFlag"

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ CMake configuration failed" -ForegroundColor Red
    exit 1
}

# Build
Write-Host "Building..." -ForegroundColor Yellow
cmake --build . --config $BuildType --target box2d

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "=========================================="  -ForegroundColor Cyan
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Output: $BuildDir\bin\$BuildType\box2d.dll" -ForegroundColor Green
Write-Host "=========================================="  -ForegroundColor Cyan

# Verify the library was created
$DllPath = Join-Path $BuildDir "bin\$BuildType\box2d.dll"
if (Test-Path $DllPath) {
    Write-Host "✓ Successfully built box2d.dll" -ForegroundColor Green
    Get-Item $DllPath | Format-Table Name, Length, LastWriteTime
    
    # Copy to the expected location
    if ($BuildType -eq "Debug") {
        $OutputDir = Join-Path $Box2DDir "libs\windows\$Architecture\debug"
    } else {
        $OutputDir = Join-Path $Box2DDir "libs\windows\$Architecture\release"
    }
    
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Copy-Item $DllPath $OutputDir -Force
    Write-Host "✓ Copied to $OutputDir\box2d.dll" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to build box2d.dll" -ForegroundColor Red
    exit 1
}
