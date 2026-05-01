#!/bin/bash

# build_app.sh
# Packages the QuickAccessAgent as a standalone macOS .app bundle.

set -e

# Ensure we are in the project root
cd "$(dirname "$0")/.."

APP_NAME="qae"
# Use swift to find the actual bin path
BUILD_DIR=$(swift build -c release --show-bin-path)
APP_BUNDLE="QuickAccessAgent.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME in release mode..."
swift build -c release

echo "Creating bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

echo "Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"

echo "Creating Info.plist..."
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.quickaccess.agent</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Copying resources..."
# Copy all SPM resource bundles (including our own and dependencies like SwiftTerm)
find "$BUILD_DIR" -maxdepth 1 -name "*.bundle" -exec cp -r {} "$RESOURCES/" \;

# Copy the app icon if it exists
if [ -f "Sources/qae/Resources/AppIcon.icns" ]; then
    cp "Sources/qae/Resources/AppIcon.icns" "$RESOURCES/"
fi

echo "Done! $APP_BUNDLE created."
echo "You can now move it to /Applications or run it with: open $APP_BUNDLE"
