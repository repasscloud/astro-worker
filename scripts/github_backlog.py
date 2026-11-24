#!/usr/bin/env python3
"""Seed GitHub project management from the checked-in catalogue."""
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess

GROUPS = {
    "type": ("1d76db", "feature bug enhancement documentation research refactor testing maintenance security"),
    "platform": ("5319e7", "android ios macos windows web shared"),
    "area": ("006b75", "architecture astronomy astrology moon planets calendar numerology spiritual birth-chart widgets notifications location storage privacy settings ui-ux accessibility performance localisation licensing ci-cd release"),
    "priority": ("b60205", "critical high medium low"),
    "status": ("fbca04", "blocked needs-decision needs-investigation needs-verification needs-hardware deferred release-blocker"),
}
MILESTONES = [
    ("Project Foundation", "Scaffold, document and validate all five runners. Resolve dependencies and distribution decisions."),
    ("Astronomical Calculation Engine", "Qualify reproducible ephemeris, observer and timezone calculations with independent fixtures."),
    ("Core Application", "Verify astronomy, astrology, event calendars and responsive navigation."),
    ("Numerology and Spiritual Content", "Verify configurable numerology and deterministic, localised editorial content."),
    ("Native Widgets", "Validate capabilities, snapshots and installation independently on each platform."),
    ("Notifications and Calendar Integration", "Validate local scheduling and interoperable calendar exports."),
    ("Personal Astrology", "Validate local profiles, house systems, charts and transits."),
    ("Cross-Platform Quality and Release", "Pass accessibility, performance, privacy and per-platform release gates."),
]


def gh(*args):
    return subprocess.check_output(["gh", *args], text=True).strip()


def main():
    repo = json.loads(gh("repo", "view", "--json", "nameWithOwner"))["nameWithOwner"]
    endpoint = f"repos/{repo}"
    with ThreadPoolExecutor(max_workers=4) as pool:
        def read(resource):
            return json.loads(gh("api", "--paginate", "--slurp", f"{endpoint}/{resource}"))
        labels, milestones, issues = pool.map(read, [
            "labels?per_page=100", "milestones?state=all&per_page=100",
            "issues?state=all&per_page=100",
        ])
        existing_labels = {item["name"] for page in labels for item in page}
        missing = [
            (f"{group}: {value}", color, f"{group.capitalize()} — {value.replace('-', ' ')}")
            for group, (color, values) in GROUPS.items() for value in values.split()
            if f"{group}: {value}" not in existing_labels
        ]
        def create_label(label):
            name, color, description = label
            gh("label", "create", name, "--repo", repo, "--color", color, "--description", description)
        list(pool.map(create_label, missing))
    existing_milestones = {item["title"] for page in milestones for item in page}
    for number, (name, description) in enumerate(MILESTONES):
        title = f"Milestone {number} — {name}"
        if title not in existing_milestones:
            gh("api", f"{endpoint}/milestones", "-f", f"title={title}", "-f", f"description={description}")
    existing = {item["title"]: item["html_url"] for page in issues for item in page if "pull_request" not in item}
    catalogue = Path(__file__).with_name("backlog.tsv").read_text().splitlines()
    for line in catalogue:
        number, kind, platform, area, priority, status, title, scope, acceptance, ref, dependency = line.split("|")
        if title not in existing:
            body = f"## Objective\n\n{scope}\n\n## Acceptance and testing\n\n- [ ] {acceptance}\n\n## References\n\n[{ref}](https://github.com/{repo}/blob/main/{ref})"
            if dependency:
                body += f"\n\n## Related work\n\n{existing[dependency]}"
            tags = [f"type: {kind}", f"platform: {platform}", f"area: {area}", f"priority: {priority}"]
            tags += [f"status: {tag}" for tag in status.split(",") if tag]
            existing[title] = gh("issue", "create", "--repo", repo, "--title", title,
                                 "--milestone", f"Milestone {number} — {MILESTONES[int(number)][0]}",
                                 "--label", ",".join(tags), "--body", body)
        print(existing[title], title, flush=True)


if __name__ == "__main__":
    main()
