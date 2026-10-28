#!/usr/bin/env bash
# Clone or update every repository in the Artivy workspace.
# Safe to re-run: local changes and non-fast-forward branches are never overwritten.
set -euo pipefail

cd "$(dirname "$0")"

hydrate_dependencies=1
if [ "${1:-}" = "--skip-deps" ]; then
    hydrate_dependencies=0
elif [ "$#" -gt 0 ]; then
    printf 'usage: %s [--skip-deps]\n' "$0" >&2
    exit 2
fi

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
    adledger
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

if (( hydrate_dependencies )); then
    # Keep all downloads in the shared per-user caches configured for the
    # workspace; only project-specific generated state remains local.
    # shellcheck disable=SC1091
    source ./workspace-env.sh

    flutter_projects=(wordle pawdoku stacko pourfect game-center)
    for name in "${flutter_projects[@]}"; do
        if [ -f "$name/pubspec.yaml" ]; then
            if (cd "$name" && flutter pub get); then
                printf '%-18s Flutter packages ready\n' "$name"
            else
                printf '%-18s FAILED   — flutter pub get\n' "$name" >&2
                failures=$((failures + 1))
            fi
        fi
    done

    android_projects=(2048 rekta adledger)
    android_sdk="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
    for name in "${android_projects[@]}"; do
        if [ -x "$name/gradlew" ]; then
            if [ ! -f "$name/local.properties" ] && [ -d "$android_sdk" ]; then
                printf 'sdk.dir=%s\n' "$android_sdk" > "$name/local.properties"
            fi
            if (cd "$name" && ./gradlew --no-daemon help); then
                printf '%-18s Gradle dependencies ready\n' "$name"
            else
                printf '%-18s FAILED   — Gradle bootstrap\n' "$name" >&2
                failures=$((failures + 1))
            fi
        fi
    done

    rust_manifests=(game-center/be/Cargo.toml artivy-p2p-engine/Cargo.toml)
    for manifest in "${rust_manifests[@]}"; do
        if [ -f "$manifest" ]; then
            if cargo fetch --manifest-path "$manifest"; then
                printf '%-18s Rust packages ready\n' "$(dirname "$manifest")"
            else
                printf '%-18s FAILED   — cargo fetch\n' "$(dirname "$manifest")" >&2
                failures=$((failures + 1))
            fi
        fi
    done
fi

if (( failures > 0 )); then
    printf '\nBootstrap completed with %d failure(s). See the messages above.\n' "$failures" >&2
    exit 1
fi

cat <<'EOF'

Toolchain these need, none of it installed by this script:
  brew install --cask flutter           # all Flutter apps, including StackO!
  Android SDK (Android Studio)          # 2048 builds with Gradle only, no Flutter
  JDK 21 for Android builds             # /usr/libexec/java_home -v 21
  Rust stable (rustup.rs)                # game-center/be, artivy-p2p-engine

Release signing reads each keystore password from the login Keychain, so a fresh
machine needs those items restored from your password manager before any release
build will work. See CLAUDE.md.

Dependencies were downloaded into shared caches. In each new terminal, enable
the same cache configuration with: source ./workspace-env.sh
EOF
