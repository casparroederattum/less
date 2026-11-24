#!/bin/bash
# Builds Less.app using only Apple's Command Line Tools (no Xcode needed).
#   ./build.sh        build
#   ./build.sh --run  build, then open the app
#   ./build.sh --demo build, then open the app with made-up data (for trying the screens)
# Everything is also written to build.log, so problems can be read back later.

set -uo pipefail
cd "$(dirname "$0")"
exec > >(tee build.log) 2>&1

echo "Building Less on $(sw_vers -productName) $(sw_vers -productVersion), $(uname -m)"
swift --version 2>&1 | head -1

if ! swift build -c release; then
  echo "BUILD FAILED"
  exit 1
fi

BIN="$(swift build -c release --show-bin-path)/Less"
APP="build/Less.app"

# A Mac app is just a folder with a fixed shape. We assemble it by hand.
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Less"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

# Ad-hoc signature: macOS needs some signature before it will show permission prompts.
codesign --force --sign - "$APP"

echo "BUILD OK: $APP"

case "${1:-}" in
  --run)  open "$APP" ;;
  --demo) open "$APP" --args --demo ;;
esac
