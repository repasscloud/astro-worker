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
