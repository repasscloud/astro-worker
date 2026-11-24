# Dependencies

| Package | Version | Purpose and licence |
| --- | --- | --- |
| Astronomia | 1.1.1 | Meeus/VSOP87 calculations, MIT |
| Shared Preferences | 2.5.6 | Lightweight local settings, BSD-3-Clause |
| Share Plus | 13.3.1 | Native file sharing and web calendar downloads, BSD-3-Clause |
| Timezone | 0.11.2 | Bundled IANA zone database, BSD-2-Clause package |
| Flutter SDK | 3.47.9 | UI and test tooling, BSD-3-Clause |

The [Dart licence inventory](../../notices/dart-dependencies.json) covers each locked package, its version, package source and the checksum of its licence or notice file. Run `flutter pub get --enforce-lockfile` and `python3 scripts/audit_dart_licenses.py --write` after reviewing an intentional change to the SDK or package graph. `scripts/check.sh` verifies the inventory against the installed files. Pass `--bundle PATH` to check a built APK or Flutter `NOTICES` file for all resolved hosted runtime package labels. The inventory covers the Dart graph. Platform build and engine dependencies still need per-channel review.

Review transitive changes from `pubspec.lock`. The local dependency guard rejects Swiss Ephemeris dependency names and common data-file extensions until the integration records the approved binding, resource provenance and corresponding source. GitHub Actions remains paused. Dependabot proposes updates for Actions and Dart packages. Review licence notices and security impact at upgrade and release, including the bundled timezone data provenance and upstream astronomy coefficient attribution.
