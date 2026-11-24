#!/usr/bin/env python3
"""Generate or check licence evidence for the resolved Flutter/Dart packages."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
from urllib.parse import urljoin, urlsplit
from urllib.request import url2pathname
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
PACKAGE_CONFIG = ROOT / ".dart_tool/package_config.json"
OUTPUT = ROOT / "notices/dart-dependencies.json"
LICENSE_STEMS = {"COPYING", "COPYRIGHT", "LICENCE", "LICENSE", "NOTICE", "NOTICES"}


def package_roots():
    resolved = json.loads(PACKAGE_CONFIG.read_text(encoding="utf-8"))
    return {
        pkg["name"]: Path(url2pathname(urlsplit(urljoin(
            PACKAGE_CONFIG.as_uri(), pkg["rootUri"]
        )).path))
        for pkg in resolved["packages"]
    }


def runtime_deps(graph, package):
    names = set()
    remaining = list(package["directDependencies"])
    while remaining:
        name = remaining.pop()
        if name not in names:
            names.add(name)
            remaining.extend(graph[name]["directDependencies"])
    return names


def evidence_for(source, sdk_root):
    files = [
        item for item in sorted(source.iterdir())
        if item.is_file() and item.name.upper().split(".", 1)[0] in LICENSE_STEMS
    ]
    if not files and source.is_relative_to(sdk_root):
        files = [sdk_root / "LICENSE"]
    return [
        {
            "file": item.name if item.parent == source else "Flutter SDK/LICENSE",
            "sha256": hashlib.sha256(item.read_bytes().replace(b"\r\n", b"\n")).hexdigest(),
        }
        for item in files
    ]


def audit():
    roots = package_roots()
    graph_json = json.loads(subprocess.check_output(
        ["dart", "pub", "deps", "--json"], cwd=ROOT, text=True
    ))
    graph = {package["name"]: package for package in graph_json["packages"]}
    root_package = graph[graph_json["root"]]
    runtime = runtime_deps(graph, root_package)
    sdk_root = roots["flutter"].parents[1]
    entries = []
    for name in sorted(graph.keys() - {root_package["name"]}):
        package = graph[name]
        evidence = evidence_for(roots[name], sdk_root)
        if not evidence:
            raise SystemExit(f"{name} {package['version']} has no licence evidence.")
        entries.append({
            "name": name,
            "version": package["version"],
            "source": package["source"],
            "runtime_graph": name in runtime,
            "evidence": evidence,
        })
    return {
        "schema": 1,
        "flutter_version": (ROOT / ".flutter-version").read_text().strip(),
        "packages": entries,
    }


def verify_bundle(path, packages):
    if path.suffix == ".apk":
        with ZipFile(path) as archive:
            data = archive.read("assets/flutter_assets/NOTICES.Z")
    else:
        data = path.read_bytes()
    if data.startswith(b"\x1f\x8b"):
        data = gzip.decompress(data)
    labels = set(data.decode("utf-8").splitlines())
    expected = {
        pkg["name"] for pkg in packages
        if pkg["runtime_graph"] and pkg["source"] == "hosted"
    }
    missing = expected - labels
    if missing:
        raise SystemExit("Bundled licence notices omit: " + ", ".join(sorted(missing)))
    print(f"Verified {len(expected)} runtime package notices in {path.name}.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Update the checked-in audit.")
    parser.add_argument(
        "--bundle", type=Path, help="Also check a built APK, NOTICES or NOTICES.Z file."
    )
    args = parser.parse_args()
    inventory = audit()
    generated = json.dumps(inventory, indent=2) + "\n"
    if args.write:
        OUTPUT.write_text(generated, encoding="utf-8")
    elif not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != generated:
        raise SystemExit("Licence audit differs. Review changes and run scripts/audit_dart_licenses.py --write.")
    packages = inventory["packages"]
    print(f"Verified licence evidence for {len(packages)} packages.")
    if args.bundle:
        verify_bundle(args.bundle, packages)


if __name__ == "__main__":
    main()
