#!/usr/bin/env bash
# Clone or update every repository in the Artivy workspace.
# Safe to re-run: local changes and non-fast-forward branches are never overwritten.
set -euo pipefail

cd "$(dirname "$0")"

# ndri-nr.github.io serves app-ads.txt from the domain root, which is the only
# place AdMob will look for it — the artivy site is a project page at /artivy/
# and structurally cannot answer for the root. Its own README explains why.
repos=(
    wordle
    pawdoku
    stacko
    2048
    rekta
    pourfect
    game-center
    artivy
    ndri-nr.github.io
    artivy-p2p-engine
)

# Match the transport used to clone artivy-studio. This lets an SSH checkout
# clone private sibling repos without unexpectedly asking for HTTPS credentials.
workspace_remote="$(git remote get-url origin 2>/dev/null || true)"
case "$workspace_remote" in
    git@github.com:*|ssh://git@github.com/*) repo_base="git@github.com:ndri-nr" ;;
    *)                                      repo_base="https://github.com/ndri-nr" ;;
esac

failures=0

for name in "${repos[@]}"; do
    if git -C "$name" rev-parse --git-dir >/dev/null 2>&1; then
        branch="$(git -C "$name" branch --show-current)"

        if [ -z "$branch" ]; then
            printf '%-18s SKIPPED  — detached HEAD; checkout a branch to update it\n' "$name"
        elif [ -n "$(git -C "$name" status --porcelain)" ]; then
            printf '%-18s SKIPPED  — local changes on %s\n' "$name" "$branch"
        elif ! git -C "$name" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
            printf '%-18s SKIPPED  — %s has no upstream branch\n' "$name" "$branch"
        elif git -C "$name" pull --ff-only; then
            printf '%-18s updated  (%s)\n' "$name" "$branch"
        else
            printf '%-18s FAILED   — could not fast-forward %s\n' "$name" "$branch" >&2
            failures=$((failures + 1))
        fi
    elif [ -e "$name" ]; then
        printf '%-18s FAILED   — exists but is not a git repo\n' "$name" >&2
        failures=$((failures + 1))
    else
        if git clone "$repo_base/$name.git" "$name"; then
            printf '%-18s cloned\n' "$name"
        else
            printf '%-18s FAILED   — clone failed\n' "$name" >&2
            failures=$((failures + 1))
        fi
    fi
done

if (( failures > 0 )); then
    printf '\nBootstrap completed with %d failure(s). See the messages above.\n' "$failures" >&2
    exit 1
fi

cat <<'EOF'

Toolchain these need, none of it installed by this script:
  brew install --cask flutter godot     # wordle, pawdoku / stacko
  Android SDK (Android Studio)          # 2048 builds with Gradle only, no Flutter
  JDK 21 for Android builds             # /usr/libexec/java_home -v 21
  Rust stable (rustup.rs)                # game-center/be, artivy-p2p-engine

2048 also needs its own local.properties pointing at the SDK — gitignored, so a
fresh clone has none:
  echo "sdk.dir=$HOME/Library/Android/sdk" > 2048/local.properties

Release signing reads each keystore password from the login Keychain, so a fresh
machine needs those items restored from your password manager before any release
build will work. See CLAUDE.md.
EOF
