#!/bin/bash
# Builds Glea Clipper for each browser from src/ into dist/:
#   dist/chrome    Chrome, Edge, Arc, Brave… (load unpacked, or the .zip for the stores)
#   dist/firefox   Firefox (about:debugging, or the .zip for addons.mozilla.org)
#   safari/        Xcode project wrapping it for Safari (with "safari")
#
#   scripts/build.sh [chrome|firefox|safari|safari-files|all]
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-all}"

# Point-and-shoot is Glea's own page script: take the latest from a Glea
# checkout next to this one (src/vendor keeps the copy last built with).
if [ -f ../glea/src/resources/content-script.js ]; then
  cp ../glea/src/resources/content-script.js src/vendor/glea-content-script.js
fi
version=$(python3 -c "import json; print(json.load(open('src/manifest.json'))['version'])")

# Copies src/ to dist/<name>, rewriting the manifest with the Python in $2.
build() {
  local name=$1 patch=$2
  rm -rf "dist/$name" "dist/glea-clipper-$name-$version.zip"
  mkdir -p "dist/$name"
  cp -R src/ "dist/$name/"
  python3 - "dist/$name/manifest.json" <<PY
import json, sys
path = sys.argv[1]
m = json.load(open(path))
$patch
json.dump(m, open(path, "w"), indent=2, ensure_ascii=False)
PY
  (cd "dist/$name" && zip -qr -X "../glea-clipper-$name-$version.zip" . -x '.*')
  echo "dist/$name  (dist/glea-clipper-$name-$version.zip)"
}

chrome() { build chrome "pass"; }

# Firefox runs background scripts (not service workers) and needs an id.
firefox() {
  build firefox '
m["background"] = {"scripts": ["background.js"]}
m["browser_specific_settings"] = {"gecko": {"id": "clipper@glea.app", "strict_min_version": "115.0"}}
'
}

# Safari takes the Firefox-style background. Glea bundles these files
# (glea/scripts/sync_clipper.sh); "safari" also wraps them in a stand-alone
# Xcode app.
safari_files() {
  build safari '
m["background"] = {"scripts": ["background.js"]}
'
}

safari() {
  safari_files
  rm -rf safari
  xcrun safari-web-extension-converter dist/safari \
    --project-location safari --app-name "Glea Clipper" \
    --bundle-identifier app.glea.clipper --swift --macos-only --copy-resources --no-open --force
  # The converter names the app after itself; its extension must be inside its id.
  sed -i '' 's/"app.glea.Glea-Clipper"/app.glea.clipper/' "safari/Glea Clipper/Glea Clipper.xcodeproj/project.pbxproj"
  echo "safari/Glea Clipper: open the .xcodeproj and run it, then enable it in Safari ▸ Settings ▸ Extensions"
}

case "$target" in
  chrome) chrome ;;
  firefox) firefox ;;
  safari) safari ;;
  safari-files) safari_files ;;
  all) chrome; firefox; safari ;;
  *) echo "usage: $0 [chrome|firefox|safari|safari-files|all]" >&2; exit 1 ;;
esac
