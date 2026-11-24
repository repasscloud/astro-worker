#!/usr/bin/env python3
"""Prevent accidental introduction of the Swiss Ephemeris distribution stack."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
lock = (root / "pubspec.lock").read_text()
restricted = re.compile(r"^  (?:sweph\w*|swisseph\w*):$", re.MULTILINE | re.IGNORECASE)
extensions = {".se1", ".se2"}
if restricted.search(lock) or any(
    path.suffix.lower() in extensions for path in (root / "assets").rglob("*")
):
    sys.exit("Swiss Ephemeris dependencies or resources require distribution approval.")
