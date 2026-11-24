# Local setup

Install Flutter from `.flutter-version` (3.47.9 with Dart 3.13.7). Run `flutter doctor -v`, then `flutter pub get --enforce-lockfile` and `flutter run -d chrome` or select the appropriate native target. Run `scripts/check.sh` for formatting, analysis and tests. On Windows, run the commands from that script in a shell with Flutter on PATH.

Use the Android SDK and JDK 17 for Android, Xcode for Apple targets and Visual Studio with Desktop development with C++ for Windows. Flutter plugin resolution may require CocoaPods where Swift Package Manager support is unavailable. Python 3 is required for PWA packaging and the GitHub bootstrap; authenticate `gh` before running `python3 scripts/github_backlog.py`.

Change `config/branding.json` and run `python3 scripts/sync_branding.py` to synchronise Dart, Android, Apple, Windows and web display metadata. The Windows distribution identifier will also need to be applied to its installer when that exists.
