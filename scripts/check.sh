#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/check_dependencies.py
flutter pub get --enforce-lockfile
python3 scripts/audit_dart_licenses.py
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos
flutter test
