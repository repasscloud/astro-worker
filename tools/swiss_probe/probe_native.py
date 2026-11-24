#!/usr/bin/env python3
"""Build and test a disposable Swiss Ephemeris C library using a pinned package."""
import argparse
import ctypes as c
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from time import perf_counter

HERE = Path(__file__).resolve().parent
FLAGS = 2 | 256
BODIES = {"sun": 0, "moon": 1, "pluto": 9, "mean_node": 10, "true_node": 11, "chiron": 15}
DATES = [2451545.0, 2460689.435416667, 2470171.5]
SOURCES = ("swecl", "swedate", "swehel", "swehouse", "swejpl", "swemmoon", "swemplan", "sweph", "swephlib")


def verified_assets(package):
    manifest = json.loads((HERE / "provenance.json").read_text())
    expected = manifest["files"]
    for relative, sha256 in expected.items():
        path = package / relative
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != sha256:
            raise SystemExit(f"Missing or corrupt pinned resource: {relative}")
    source = package / "native/sweph/src"
    digest = hashlib.sha256()
    files = sorted([source / (name + ".c") for name in SOURCES] + list(source.glob("*.h")))
    for file in files:
        content = file.read_bytes().replace(b"\r\n", b"\n")
        digest.update(file.name.encode() + b"\0" + hashlib.sha256(content).digest())
    if digest.hexdigest() != manifest["native_source_sha256"]:
        raise SystemExit("Native source digest differs from the pinned package.")
    return [package / relative for relative in expected if relative.endswith(".se1")]


def compile_library(source, target):
    sources = [str(source / (name + ".c")) for name in SOURCES]
    if sys.platform == "win32":
        command = ["cl", "/nologo", "/O2", "/LD", "/DMAKE_DLL", "/D_CRT_SECURE_NO_WARNINGS"]
        command += sources + ["/link", f"/OUT:{target}"]
    else:
        mode = "-dynamiclib" if sys.platform == "darwin" else "-shared"
        command = ["cc", "-O2", mode, "-fPIC", *sources, "-o", str(target)]
    subprocess.run(command, cwd=target.parent, check=True, stdout=sys.stderr)


def probe(library, assets, empty):
    sweph = c.CDLL(str(library))
    sweph.swe_set_ephe_path.argtypes = [c.c_char_p]
    sweph.swe_calc_ut.argtypes = [c.c_double, c.c_int32, c.c_int32, c.POINTER(c.c_double), c.c_char_p]
    sweph.swe_calc_ut.restype = c.c_int32
    values = (c.c_double * 6)()
    error = c.create_string_buffer(256)

    def calculate(body_id, julian_day):
        flags = sweph.swe_calc_ut(julian_day, body_id, FLAGS, values, error)
        return flags, list(values)

    sweph.swe_set_ephe_path(str(empty).encode())
    missing_flags, _ = calculate(BODIES["moon"], DATES[1])
    assert missing_flags < 0 or missing_flags & 7 != 2, "Missing assets did not fail strict flags."
    sweph.swe_close()
    sweph.swe_set_ephe_path(str(assets).encode())
    samples = []
    for name, body_id in BODIES.items():
        for date in DATES:
            flags, value = calculate(body_id, date)
            assert flags >= 0 and flags & 7 == 2, f"{name} did not return Swiss flags: {flags}"
            samples.append({"body": name, "jd_ut": date, "longitude": value[0], "flags": flags})

    edged = []
    sweph.swe_julday.argtypes = [c.c_int, c.c_int, c.c_int, c.c_double, c.c_int]
    sweph.swe_julday.restype = c.c_double
    for year in (1801, 2399):
        date = sweph.swe_julday(year, 1, 1, 0, 1)
        flags, _ = calculate(BODIES["moon"], date)
        assert flags >= 0 and flags & 7 == 2, f"Unexpected lunar coverage at {year}"
        edged.append(year)

    start = perf_counter()
    for index in range(2048):
        calculate(BODIES["moon"], DATES[1] + index / 24)
    speed = round(2048 / (perf_counter() - start))
    sweph.swe_close()
    if sys.platform == "win32":
        free_library = c.WinDLL("kernel32").FreeLibrary
        free_library.argtypes = [c.c_void_p]
        free_library(sweph._handle)
    return {
        "missing_moon_flags": missing_flags,
        "coverage_years": edged,
        "library_bytes": library.stat().st_size,
        "moon_calls_per_second": speed,
        "samples": samples,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    parser.add_argument("--verify-only", action="store_true", help="Verify inputs without compiling.")
    args = parser.parse_args()
    package = args.package.resolve()
    assets = verified_assets(package)
    if args.verify_only:
        print("Pinned Swiss Ephemeris source and asset digests match.")
        return
    with tempfile.TemporaryDirectory(prefix="astro-swiss-") as root:
        root = Path(root)
        directory = root / "ephe"
        directory.mkdir()
        empty = root / "empty"
        empty.mkdir()
        for asset in assets:
            shutil.copyfile(asset, directory / asset.name)
        suffix = {"darwin": ".dylib", "win32": ".dll"}.get(sys.platform, ".so")
        library = root / ("sweph" + suffix)
        compile_library(package / "native/sweph/src", library)
        print(json.dumps(probe(library, directory, empty), indent=2))


if __name__ == "__main__":
    main()
