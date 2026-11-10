#!/bin/bash
# scripts/bundle.sh — Build SPM executable, package into Glide.app, and apply ad-hoc codesign.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="Glide"
BUNDLE_ID="xyz.edgebar.glide"
APP_DIR="${ROOT}/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RES_DIR="${CONTENTS}/Resources"
CONFIG="${1:-release}"

echo "==> Building Glide (${CONFIG})..."
swift build -c "${CONFIG}"

BIN_PATH=$(swift build -c "${CONFIG}" --show-bin-path)
BIN="${BIN_PATH}/${APP_NAME}"

if [ ! -f "${BIN}" ]; then
  echo "Error: Expected binary at ${BIN}" >&2
  exit 1
fi

echo "==> Assembling ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"

cp "${BIN}" "${MACOS_DIR}/${APP_NAME}"

if [ "${CONFIG}" = "release" ]; then
  echo "==> Stripping symbols for release..."
  strip -rSTx "${MACOS_DIR}/${APP_NAME}" 2>/dev/null || true
fi

# Resources
if [ -f "${ROOT}/Resources/AppIcon.icns" ]; then
  cp "${ROOT}/Resources/AppIcon.icns" "${RES_DIR}/"
fi

# Info.plist
if [ -f "${ROOT}/Resources/Info.plist" ]; then
  cp "${ROOT}/Resources/Info.plist" "${CONTENTS}/Info.plist"
else
  cat > "${CONTENTS}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.2</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST
fi

plutil -lint "${CONTENTS}/Info.plist" > /dev/null

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Successfully bundled: ${APP_DIR}"

if [ "${CONFIG}" = "release" ]; then
  echo "==> Creating distributable ${ROOT}/${APP_NAME}.zip..."
  rm -f "${ROOT}/${APP_NAME}.zip"
  ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${ROOT}/${APP_NAME}.zip"
  echo "==> Distributable package ready at: ${ROOT}/${APP_NAME}.zip"
fi

echo "To test run: open \"${APP_DIR}\""
