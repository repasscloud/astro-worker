# Build commands

| Target | Command |
| --- | --- |
| Web | `scripts/build_web.sh` |
| Android | `flutter build apk --debug` |
| iOS | `flutter build ios --simulator --no-codesign` |
| macOS | `flutter build macos --debug` |
| Windows | `flutter build windows --debug` |

Host `build/web` on HTTPS or a secure localhost context; deploy the directory atomically and serve `offline-worker.js` with a revalidation policy. Pass `--base-href /path/` to the build script when serving from a subpath. The application uses a bundled renderer and versioned precache. Keep signing and storefront deployment outside pull request validation.

Update `.flutter-version`, SDK constraints and lockfile together in a toolchain change. Rerun all builds and update the compatibility matrix.

Run macOS desktop validation locally with `scripts/check.sh`, `flutter build macos --debug` and `flutter test integration_test -d macos`. The desktop matrix entry and its integration test step are commented out in `.github/workflows/validate.yml` so they can be re-enabled together.

GitHub Actions validation is currently paused for every target. The workflow preserves the build matrix and verification steps as comments. The skipped placeholder keeps the workflow valid without allocating a runner. Run `scripts/check.sh` and the applicable target commands locally.

For a local device smoke test, boot an iOS simulator or connect an Android test device, then use `flutter devices` to find its ID and run `flutter test integration_test -d DEVICE_ID`. For browser coverage, run `flutter test --platform chrome test`, then use the packaged web build to verify an offline reload over localhost.
