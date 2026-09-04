#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
sh -n install_gcr.sh
zsh -n .ohmyzsh
zsh -n .p9k.zsh
for file in .ohmyshell .ohmytool .ohmyprint config/*.sh lib/*.sh lib/installers/*.sh; do
    bash -n "$file"
    zsh -n "$file"
done
python3 scripts/manifest.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
