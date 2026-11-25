#!/usr/bin/env python3
"""Build the Swiss candidate from verified source and compare the sample grid."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from probe_native import HERE, SOURCES, verified_assets


def probe(package, script=HERE / "probe_wasm.mjs"):
    result = json.loads(subprocess.check_output(["node", str(script), str(package)]))
    return result["samples"], result["missing_moon_flags"]


def rebuild(package, directory, spec):
    source = directory / "src"
    output = directory / "assets"
    data = output / "ephe"
    data.mkdir(parents=True)
    for file in verified_assets(package):
        shutil.copyfile(file, data / file.name)
    shutil.copytree(package / "native/sweph/src", source)
    (source / "utils").mkdir()
    for name, digest in spec["glue"].items():
        glue = (package / "native/utils" / name).read_bytes().replace(b"\r\n", b"\n")
        if hashlib.sha256(glue).hexdigest() != digest:
            raise SystemExit(f"Unexpected Wasm glue digest: {name}")
        (source / "utils" / name).write_bytes(glue)

    subprocess.run([
        "docker", "run", "--rm", "--network=none", "--platform", spec["platform"],
        "-v", f"{source}:/src:ro", "-v", f"{output}:/dist", spec["image"],
        "emcc", "-o", "/dist/sweph.wasm", "-fPIC", "-Oz", "-fno-exceptions",
        "-fno-rtti", "-fno-stack-protector", "-ffunction-sections", "-fdata-sections",
        "-fno-math-errno", "-DNDEBUG", "-Wl,--gc-sections,--no-entry,--export=__wasm_call_ctors",
        *(f"{name}.c" for name in SOURCES), "utils/mem_io.c",
        "-D", "fopen=fOpen", "-D", "fclose=fClose", "-D", "fread=fRead",
        "-D", "fwrite=fWrite", "-D", "rewind=fRewind", "-D", "fseek=fSeek",
        "-D", "ftell=fTell", "-D", "fgets=fGets", "-D", "printf=printF",
        "-D", "getenv=fakeGetenv", "-D", "NO_SWE_GLP",
        "-s", 'EXPORTED_FUNCTIONS=["_malloc","_free","_write_file"]',
        "-s", "FILESYSTEM=0", "-s", "STANDALONE_WASM=1",
    ], check=True)
    digest = hashlib.sha256((output / "sweph.wasm").read_bytes()).hexdigest()
    if digest != spec["sha256"]:
        raise SystemExit(f"Unexpected rebuilt Wasm digest: {digest}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    package = parser.parse_args().package.resolve()
    manifest = json.loads((HERE / "provenance.json").read_text())
    spec = manifest["wasm_rebuild"]
    with tempfile.TemporaryDirectory(prefix="astro-swiss-source-") as temp:
        directory = Path(temp).resolve()
        rebuild(package, directory, spec)
        published = probe(package)
        manifest["files"]["assets/sweph.wasm"] = spec["sha256"]
        (directory / "provenance.json").write_text(json.dumps(manifest), encoding="utf-8")
        script = directory / "probe_wasm.mjs"
        shutil.copyfile(HERE / script.name, script)
        if probe(directory, script) != published:
            raise SystemExit("Rebuilt Wasm differs from the published sample or fallback results.")
    print("Verified the pinned source rebuild, sample grid and missing-file flags.")


if __name__ == "__main__":
    main()
