#!/bin/zsh
# Builds "Hex Picker.app" and packages it as build/HexPicker.dmg
set -e
cd "$(dirname "$0")"
APP="Hex Picker.app"
rm -rf "build/$APP"
mkdir -p "build/$APP/Contents/MacOS"
xcrun swiftc -O main.swift -o "build/$APP/Contents/MacOS/HexPicker"
cat > "build/$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Hex Picker</string>
  <key>CFBundleIdentifier</key><string>local.hexpicker</string>
  <key>CFBundleExecutable</key><string>HexPicker</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
codesign --force --sign - "build/$APP"
# DMG with the app and an Applications shortcut to drag it onto
STAGE=build/dmg
rm -rf "$STAGE" build/HexPicker.dmg
mkdir -p "$STAGE"
cp -R "build/$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Hex Picker" -srcfolder "$STAGE" -ov -format UDZO build/HexPicker.dmg >/dev/null
rm -rf "$STAGE"
echo "Built build/HexPicker.dmg"
