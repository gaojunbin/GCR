#!/usr/bin/env python3
"""Generate or verify the checksum manifest used by the GCR updater."""
import argparse
import hashlib
from pathlib import Path
import subprocess


def manifest(root):
    output = subprocess.check_output(
        ["sh", "-c", '. "$1/lib/core.sh"; gcr_payload_files', "sh", str(root)],
        text=True,
    )
    return "".join(
        "{}  {}\n".format(hashlib.sha256((root / name).read_bytes()).hexdigest(), name)
        for name in output.splitlines()
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    target = root / "manifest.sha256"
    content = manifest(root)
    if args.write:
        target.write_text(content)
    elif not target.exists() or target.read_text() != content:
        raise SystemExit("Manifest is stale. Run: python3 scripts/manifest.py --write")


if __name__ == "__main__":
    main()
