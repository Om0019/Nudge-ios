#!/usr/bin/env python3
"""Updates apps.json (the AltStore/SideStore source manifest) with a new
release entry. Run after building and publishing Nudge.ipa as a GitHub
Release asset.
"""
import argparse
import json
import pathlib
import sys

MANIFEST_PATH = pathlib.Path(__file__).resolve().parent.parent / "apps.json"
BUNDLE_ID = "com.nudgeapp.ios"
REPO = "om0019/nudge-ios"


def load_manifest() -> dict:
    if MANIFEST_PATH.exists():
        return json.loads(MANIFEST_PATH.read_text())
    return {
        "name": "Nudge",
        "identifier": "com.nudgeapp.ios.altstore-source",
        "sourceURL": f"https://raw.githubusercontent.com/{REPO}/main/apps.json",
        "apps": [
            {
                "name": "Nudge",
                "bundleIdentifier": BUNDLE_ID,
                "developerName": "Nudge",
                "subtitle": "A calm, customizable planner for ADHD brains",
                "localizedDescription": (
                    "Nudge is a free, ADHD-friendly planner with a visual timeline, "
                    "gentle reminders, a focus timer, and Home Screen widgets — with "
                    "an accent color and layout you control."
                ),
                "iconURL": f"https://raw.githubusercontent.com/{REPO}/main/Nudge/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
                "tintColor": "FF6A1D",
                "versions": [],
            }
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--date", required=True, help="ISO 8601, e.g. 2026-08-24T00:00:00Z")
    parser.add_argument("--size", required=True, type=int, help="ipa size in bytes")
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--download-url", required=True)
    parser.add_argument("--notes", default="")
    args = parser.parse_args()

    manifest = load_manifest()
    app = manifest["apps"][0]

    version_entry = {
        "version": args.version,
        "date": args.date,
        "size": args.size,
        "sha256": args.sha256,
        "downloadURL": args.download_url,
        "localizedDescription": args.notes or f"Nudge {args.version}",
        "minOSVersion": "17.0",
    }

    versions = app.setdefault("versions", [])
    versions = [v for v in versions if v.get("version") != args.version]
    versions.insert(0, version_entry)
    app["versions"] = versions

    # Mirror the latest release at the top level for older AltStore parsers
    # that don't read the "versions" array.
    app["version"] = args.version
    app["versionDate"] = args.date
    app["size"] = args.size
    app["sha256"] = args.sha256
    app["downloadURL"] = args.download_url

    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Updated {MANIFEST_PATH} with version {args.version}")


if __name__ == "__main__":
    sys.exit(main())
