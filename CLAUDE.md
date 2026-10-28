# Artivy workspace contributor notes

## Repository boundaries

The workspace root tracks only bootstrap/shared documentation. Every child is an
independent repository and must be committed and pushed separately. Never treat
the children as submodules or combine their release versions.

## Bootstrap and caches

`bootstrap.sh` owns the complete repository list. Add a new product there and in
the root README. It is safe to rerun: dirty, detached, divergent, or no-upstream
checkouts are reported rather than rewritten.

`workspace-env.sh` centralizes only caches that are designed to be shared:
`~/.gradle`, `~/.pub-cache`, `~/.cargo`, and `.cache/cargo-target`. Keep project
state (`.dart_tool`, project `.gradle`, and `build`) local. Do not introduce a
per-project `GRADLE_USER_HOME`; it duplicates downloads across Android apps.

## Current stacks

- Flutter: `wordle`, `pawdoku`, `stacko`, `pourfect`, `game-center`
- Native Android: `2048`, `rekta`
- Rust: `game-center/be`, `artivy-p2p-engine`
- Static web: `artivy`, `ndri-nr.github.io`

StackO! is Flutter-only. Godot, its export templates, plugins, and generated
Android host are retired. Its production application ID remains
`id.artivy.stacko`.

## Normal verification

Flutter project:

```sh
dart format lib test
flutter analyze
flutter test
flutter build appbundle --release
```

Native Android project:

```sh
./gradlew test
./gradlew bundleRelease
```

Rust project:

```sh
cargo fmt --check --manifest-path path/to/Cargo.toml
cargo test --manifest-path path/to/Cargo.toml
```

Follow each project's own instructions where they are stricter. Release builds
produce AABs only; do not build an APK unless the user explicitly asks for one.

## Production identities and signing

Never change an existing package ID or reuse an uploaded version code. Keystores
live outside repositories under `~/key-store`; ignored `key.properties` files
contain alias/path only. Passwords come from macOS login Keychain. Never print,
copy into shell history, or commit passwords.

StackO! specifically uses package `id.artivy.stacko`, alias `stacko-upload`, and
Keychain service `stacko-upload-keystore`.

## Ads, privacy, and legal pages

Production ad IDs and Firebase configuration are product-specific. Do not copy
IDs between apps. Child-directed configuration, neutral age gating, consent, ad
frequency caps, and privacy choices must remain intact.

An app behavior change that affects collection, storage, analytics, advertising,
accounts, or deletion also requires reviewing `artivy/games/<slug>/`. Runtime
URLs omit `games/` because the Pages deploy flattens that directory.

The publisher declaration must remain at `ndri-nr.github.io/app-ads.txt`; the
`artivy` project site cannot serve the domain root crawled by AdMob.

## Cleanup

Generated Flutter/Gradle output may be removed with project-native clean tasks.
Preserve store assets under each project's `release/` directory. Never delete a
workspace root, a shared dependency cache, keystores, or user-authored dirty
changes as cleanup.

After copying a release AAB to the workspace `builds/` directory with its
versioned filename and verifying the copy, delete all generated `.aab` and
`.apk` files left under the source repository's `build/` directories, including
intermediary bundles. The versioned file in `builds/` is the only retained
release artifact; this rule applies to every app repository in the workspace.

Game Center release AABs must always be built with both production Dart defines
from `game-center/CLAUDE.md`: `API_BASE=https://artiverse.bug.ai.id` and the
documented `PLAY_CLIENT_ID`. A build without either define is an offline build
without accounts, leaderboards, or Play Games and must never be copied to
`builds/` or handed off as a release artifact.
