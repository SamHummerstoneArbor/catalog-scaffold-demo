#!/usr/bin/env bash
# Prints one section of README.md so the demo-replay workflow narrates from the README
# itself instead of a second, hand-copied stash of prose that can drift out of sync.
#
# Usage:
#   print-readme-section.sh --intro     # everything before the first "## " heading
#   print-readme-section.sh "Act 3"     # the "## Act 3 ..." section, up to the next "## " heading
set -euo pipefail

readme="$(cd "$(dirname "$0")/../.." && pwd)/README.md"

if [ "$1" = "--intro" ]; then
  awk '/^## /{exit} {print}' "$readme"
else
  awk -v heading="## $1" '
    index($0, heading) == 1 { found=1; print; next }
    found && /^## / { exit }
    found { print }
  ' "$readme"
fi
