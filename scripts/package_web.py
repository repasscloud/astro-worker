#!/usr/bin/env python3
"""Build a scoped, content-addressed service worker for a Flutter web build."""
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import quote

root = Path(sys.argv[1])
template = Path(__file__).resolve().parents[1] / "web/offline-worker.js"
required = ["index.html", "flutter_bootstrap.js", "main.dart.js", "manifest.json"]
for name in required:
    if not (root / name).is_file():
        sys.exit(f"Expected standard JavaScript Flutter web build file: {name}")

digest = hashlib.sha256(template.read_bytes())
assets = []
for path in sorted(root.rglob("*")):
    if not path.is_file() or path.name in {
        "offline-worker.js", "flutter_service_worker.js", ".last_build_id",
    } or path.suffix == ".map":
        continue
    name = quote(path.relative_to(root).as_posix())
    assets.append(name)
    digest.update(name.encode())
    digest.update(hashlib.sha256(path.read_bytes()).digest())

worker = template.read_text().replace("/* BUILD_ID */", json.dumps(digest.hexdigest()[:20]))
worker = worker.replace("/* BUILD_ASSETS */", json.dumps(assets))
(root / "offline-worker.js").write_text(worker)
