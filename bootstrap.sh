#!/usr/bin/env bash
# Clone the four Artivy repos into this workspace, or report what is already here.
# Safe to re-run: an existing directory is left alone.
set -euo pipefail

cd "$(dirname "$0")"

repos=(wordle pawdoku stacko artivy)

for name in "${repos[@]}"; do
    if [ -d "$name/.git" ]; then
        # Not `git pull`: each repo may hold work in progress, and pulling on the
        # user's behalf is not this script's business.
        printf '%-9s present  (%s)\n' "$name" "$(git -C "$name" rev-parse --abbrev-ref HEAD)"
    elif [ -e "$name" ]; then
        printf '%-9s SKIPPED  — exists but is not a git repo\n' "$name"
    else
        git clone "https://github.com/ndri-nr/$name.git" "$name"
    fi
done

cat <<'EOF'

Toolchain these need, none of it installed by this script:
  brew install --cask flutter godot     # wordle, pawdoku / stacko
  JDK 21 for Android builds             # /usr/libexec/java_home -v 21

Release signing reads each keystore password from the login Keychain, so a fresh
machine needs those items restored from your password manager before any release
build will work. See CLAUDE.md.
EOF
