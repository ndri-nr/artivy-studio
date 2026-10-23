#!/usr/bin/env bash
# Source this file before building projects in this workspace:
#   source ./workspace-env.sh

if [ -n "${BASH_VERSION:-}" ]; then
    workspace_env_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    workspace_env_file="${(%):-%N}"
else
    printf 'workspace-env.sh supports Bash and Zsh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ARTIVY_STUDIO_ROOT="$(cd "$(dirname "$workspace_env_file")" && pwd)"
export ARTIVY_STUDIO_ROOT

# These dependency stores are already shared by every project on the machine.
# Defining them explicitly prevents tools or IDE tasks from choosing a local
# project cache instead.
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

# Cargo normally compiles the same dependencies once in each service's target/
# directory. A common target directory lets compatible artifacts be reused.
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$ARTIVY_STUDIO_ROOT/.cache/cargo-target}"

# Enable Gradle's shared local build cache for the Flutter Android projects too.
case " ${GRADLE_OPTS:-} " in
    *" -Dorg.gradle.caching="*) ;;
    *) export GRADLE_OPTS="${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.caching=true" ;;
esac

mkdir -p "$CARGO_TARGET_DIR"

printf 'Artivy shared caches enabled:\n'
printf '  Gradle dependencies/build cache: %s\n' "$GRADLE_USER_HOME"
printf '  Dart/Flutter packages:           %s\n' "$PUB_CACHE"
printf '  Cargo packages:                  %s\n' "$CARGO_HOME"
printf '  Shared Rust build output:        %s\n' "$CARGO_TARGET_DIR"

unset workspace_env_file
