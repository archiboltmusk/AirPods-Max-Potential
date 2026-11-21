#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Determine Version: from argument, git tag, or fallback to 1.3.0
if [ -n "$1" ]; then
    VERSION="$1"
else
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ "$GIT_TAG" =~ ^v[0-9] ]]; then
        VERSION="${GIT_TAG#v}"
    else
        VERSION="1.3.0"
    fi
fi

echo "🚀 Building AirPodsPosture v${VERSION}..."

# Attempt Universal 2 build (arm64 + x86_64), fallback to native architecture
echo "🔨 Compiling Swift binary in Release mode..."
if swift build -c release --arch arm64 --arch x86_64 2>/dev/null; then
    echo "✅ Universal 2 binary (arm64 + x86_64) compiled successfully."
else
    echo "⚠️ Universal compile not available; falling back to native release build..."
    swift build -c release
    echo "✅ Native binary compiled successfully."
fi

# Locate compiled binary
BINARY_SRC=""
for CANDIDATE in \
    "$DIR/.build/out/Products/Release/AirPodsPosture" \
    "$DIR/.build/apple/Products/Release/AirPodsPosture" \
    "$DIR/.build/release/AirPodsPosture"; do
    if [ -f "$CANDIDATE" ]; then
        BINARY_SRC="$CANDIDATE"
        break
    fi
done

if [ -z "$BINARY_SRC" ]; then
    echo "❌ Error: Could not locate compiled AirPodsPosture binary!"
    exit 1
fi

echo "📍 Found binary at: $BINARY_SRC"
lipo -info "$BINARY_SRC" || true

APP_NAME="AirPodsPosture.app"
APP_DIR="$DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Assembling $APP_NAME bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BINARY_SRC" "$MACOS_DIR/AirPodsPosture"
chmod +x "$MACOS_DIR/AirPodsPosture"

# Copy Resources
if [ -d "$DIR/Sources/AirPodsPosture/Resources" ]; then
    cp -R "$DIR/Sources/AirPodsPosture/Resources/"* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Create Info.plist
cat << EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AirPodsPosture</string>
    <key>CFBundleIdentifier</key>
    <string>com.archiboltmusk.airpodsposture</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AirPods Posture</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMotionUsageDescription</key>
    <string>AirPods Posture uses headphone motion tracking to actively monitor neck angle and posture.</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>AirPods Posture uses Bluetooth to detect connected AirPods Max and AirPods Pro.</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>AirPods Posture connects to AirPods motion sensors to track head orientation.</string>
    <key>NSCameraUsageDescription</key>
    <string>AirPods Posture uses FaceTime HD / Continuity Camera on-device Apple Neural Engine facial pose estimation to maintain unbroken posture tracking when your AirPods are charging in their case.</string>
</dict>
</plist>
EOF

echo "🔏 Signing bundle with adhoc signature & sealed Info.plist..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ App bundle created successfully at: $APP_DIR"

# 1. Package ZIP Archive
ZIP_NAME="AirPodsPosture-v${VERSION}-macOS.zip"
echo "📦 Packaging $ZIP_NAME..."
rm -f "$DIR/$ZIP_NAME"
ditto -c -k --keepParent "$APP_DIR" "$DIR/$ZIP_NAME"

# 2. Package Apple Disk Image (DMG)
DMG_NAME="AirPodsPosture-v${VERSION}-macOS.dmg"
echo "💿 Creating Apple Disk Image $DMG_NAME..."
TMP_DMG=$(mktemp -d /tmp/dmg_build_XXXXXX)
chmod 755 "$TMP_DMG"
cp -R "$APP_DIR" "$TMP_DMG/"
ln -s /Applications "$TMP_DMG/Applications"
chmod -R u+rwX,go+rX "$TMP_DMG"
rm -f "$DIR/$DMG_NAME"
hdiutil create -volname "AirPods Posture" -srcfolder "$TMP_DMG" -ov -format UDZO "$DIR/$DMG_NAME" > /dev/null
rm -rf "$TMP_DMG"

# 3. Generate SHA256 Checksums
echo "📝 Generating SHA256SUMS.txt..."
cd "$DIR"
shasum -a 256 "$DMG_NAME" "$ZIP_NAME" > "SHA256SUMS.txt"
cat "SHA256SUMS.txt"

echo "🎉 All release distribution artifacts built successfully!"
ls -lh "$DIR/$DMG_NAME" "$DIR/$ZIP_NAME"
