#!/usr/bin/env python3
"""Stage an official build with its source and a hash manifest for review."""
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect(target, into, stem):
    if target == "web":
        return Path(shutil.make_archive(str(into / stem), "zip", BUILD / "web"))
    if target == "macos":
        artifact = into / f"{stem}.zip"
        source = BUILD / "macos/Build/Products/Release/astro_worker.app"
        subprocess.run(
            ["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(source), str(artifact)],
            check=True,
        )
        return artifact
    if target == "windows":
        architecture = "arm64" if platform.machine().lower() in {"arm64", "aarch64"} else "x64"
        runner = BUILD / f"windows/{architecture}/runner/Release"
        return Path(shutil.make_archive(str(into / stem), "zip", runner))
    source = {
        "apk": BUILD / "app/outputs/flutter-apk/app-release.apk",
        "appbundle": BUILD / "app/outputs/bundle/release/app-release.aab",
    }[target]
    if source is None or not source.is_file():
        raise SystemExit(f"Expected build artifact for {target}.")
    artifact = into / (stem + source.suffix)
    shutil.copy2(source, artifact)
    return artifact


def source_url(revision):
    return f"https://github.com/repasscloud/astro-worker/tree/{revision}"


def main():
    target, version, number, revision, short, legacy_metadata = sys.argv[1:]
    metadata = {
        "target": target,
        "version": version,
        "displayVersion": f"{version} build {short}",
        "packageBuildNumber": int(number),
        "sourceRevision": revision,
        "sourceUrl": source_url(revision),
    }
    if target == "ipa":
        Path(legacy_metadata).write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        return
    staging = BUILD / "releases"
    staging.mkdir(exist_ok=True)
    stem = f"astro-worker-{target}-{version}-{number}-{short}"
    destination = staging / stem
    if destination.exists():
        raise SystemExit(f"Release staging already exists: {destination}")

    with tempfile.TemporaryDirectory(prefix="stage-", dir=staging) as scratch:
        temporary = Path(scratch)
        artifact = collect(target, temporary, stem)
        source = temporary / f"astro-worker-source-{short}.tar.gz"
        subprocess.run(
            ["git", "archive", "--format=tar.gz", f"--prefix=astro-worker-{short}/",
             f"--output={source}", revision],
            cwd=ROOT,
            check=True,
        )
        metadata.update({
            "artifact": {"name": artifact.name, "sha256": sha256(artifact)},
            "projectSourceArchive": {"name": source.name, "sha256": sha256(source)},
        })
        text = json.dumps(metadata, indent=2) + "\n"
        (temporary / "release.json").write_text(text, encoding="utf-8")
        temporary.rename(destination)
    Path(legacy_metadata).write_text(text, encoding="utf-8")
    print(f"Staged release candidate: {destination.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
