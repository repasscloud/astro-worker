# Swiss Ephemeris qualification probes

These developer-only probes evaluate the AGPL candidate `sweph 4.1.0+2.10.3` without adding it to the app's dependencies. They compile or load the exact candidate into a disposable process and reject calculations that return a different ephemeris flag.

Fetch the package into the local Dart cache with `dart pub cache add sweph --version '4.1.0+2.10.3'`. Pass its directory to the probes below. [Pinned package](https://pub.dev/packages/sweph/versions/4.1.0+2.10.3), [native and Wasm licensing inventory](https://github.com/vm75/sweph.dart/blob/master/LICENSING.md)

- `python3 tools/swiss_probe/probe_native.py PACKAGE_ROOT` builds and probes the C sources on macOS, Linux, or Windows. Windows uses an x64 Visual Studio developer shell.
- `node tools/swiss_probe/probe_wasm.mjs PACKAGE_ROOT` tests the packaged WebAssembly binary and its in-memory resources without a network connection.
- `python3 tools/swiss_probe/rebuild_wasm.py PACKAGE_ROOT` builds from the checksummed C and memory I/O sources with Docker and compares the result with the published candidate's offline probe. The pinned Emscripten Linux arm64 image may need a first download. The build container runs without networking and uses a temporary directory.
- `bash tools/swiss_probe/probe_android.sh SERIAL PACKAGE_ROOT NDK_CLANG` builds a disposable Android probe and pushes it to a test device. Supply the NDK compiler for the test device architecture, for example `aarch64-linux-android24-clang`. The tool removes its device test directory when it exits.

The probes check the source and resource checksums, strict Swiss flags, missing resources, and Sun, Moon, Pluto, Chiron, and lunar node sample results. The C probe also measures the interval endpoints sampled and a short warmed Moon series. The application remains on Astronomia.

The upstream Makefile uses an unversioned compiler image. With Emscripten 4.0.23 pinned to its image digest, two local builds produced the same WebAssembly digest. The rebuilt bytes differ from the published package binary. All 18 longitude samples and the missing-file result matched the published candidate. This establishes a reproducible build path for the evaluated sources. [Upstream Makefile](https://github.com/vm75/sweph.dart/blob/v4.1.0%2B2.10.3/Makefile)
