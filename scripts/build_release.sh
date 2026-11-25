#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

target=${1:-}
package_build=${2:-}
case "$target" in
  web|apk|appbundle|ipa|macos|windows) ;;
  *) echo "Usage: scripts/build_release.sh {web|apk|appbundle|ipa|macos|windows} PACKAGE_BUILD" >&2; exit 2 ;;
esac
if [[ $# != 2 || ! "$package_build" =~ ^[1-9][0-9]*$ ]]; then
  echo "Supply a positive numeric package build number." >&2
  exit 2
fi
if [[ "$target" == apk || "$target" == appbundle ]]; then
  for key in ASTRO_ANDROID_KEYSTORE ASTRO_ANDROID_STORE_PASSWORD ASTRO_ANDROID_KEY_ALIAS ASTRO_ANDROID_KEY_PASSWORD; do
    if [[ -z "${!key:-}" ]]; then
      echo "Set $key to build an official signed Android package." >&2
      exit 2
    fi
  done
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Release builds require a clean committed checkout." >&2
  exit 1
fi

version=$(sed -n 's/^version: \([0-9.]*\)+[0-9]*$/\1/p' pubspec.yaml)
test -n "$version"
revision=$(git rev-parse HEAD)
short_revision=$(git rev-parse --short=12 "$revision")
sdk_version=$(cat .flutter-version)
if ! flutter --version --machine | python3 -c '
import json, sys
sys.exit(json.load(sys.stdin)["frameworkVersion"] != sys.argv[1])
' "$sdk_version"; then
  echo "Use Flutter $sdk_version for release builds." >&2
  exit 1
fi

metadata="build/release-$target.json"
rm -f "$metadata"
flutter pub get --enforce-lockfile
python3 scripts/audit_dart_licenses.py
options=(
  # Flutter regenerates the release plugin registrants when pub is enabled.
  --release
  "--build-name=$version" "--build-number=$package_build"
  "--dart-define=ASTRO_VERSION=$version"
  "--dart-define=ASTRO_BUILD_HASH=$short_revision"
  "--dart-define=ASTRO_SOURCE_REVISION=$revision"
)
if [[ "$target" == web ]]; then
  scripts/build_web.sh "${options[@]}"
else
  flutter build "$target" "${options[@]}"
fi

if [[ "$(git rev-parse HEAD)" != "$revision" || -n "$(git status --porcelain)" ]]; then
  echo "The checkout changed while building. Discard this build." >&2
  exit 1
fi
python3 scripts/stage_release.py "$target" "$version" "$package_build" "$revision" "$short_revision" "$metadata"
