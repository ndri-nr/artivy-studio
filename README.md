# artivy-studio

Workspace launcher and shared documentation for the Artivy apps, services, and
publisher site. Each child directory is an independent Git repository with its
own release history.

## Projects

| Directory | Product | Stack |
|---|---|---|
| `wordle/` | Kata·Word | Flutter |
| `pawdoku/` | Pawdoku | Flutter |
| `stacko/` | StackO! | Flutter |
| `pourfect/` | PourFect! | Flutter |
| `game-center/` | Artiverse app and backend | Flutter + Rust |
| `2048/` | 2048 | Native Android |
| `rekta/` | Rekta | Native Android |
| `adledger/` | AdLedger | Native Android |
| `artivy-p2p-engine/` | Multiplayer duel service | Rust |
| `artivy/` | Product/legal website | Static web |

## Bootstrap a machine

```sh
git clone https://github.com/ndri-nr/artivy-studio.git
cd artivy-studio
./bootstrap.sh
```

The script:

- clones every missing related repository;
- fast-forwards clean existing checkouts without overwriting local work;
- uses the same SSH or HTTPS transport as this repository;
- downloads Flutter, Gradle, and Rust dependencies into shared caches;
- writes missing native-Android `local.properties` when the standard SDK path
  exists.

Use `./bootstrap.sh --skip-deps` when only repository synchronization is wanted.

## Shared caches

In every new terminal:

```sh
source ./workspace-env.sh
```

This standardizes:

- Gradle dependencies and build cache: `~/.gradle`
- Flutter/Dart packages: `~/.pub-cache`
- Rust registry and Git dependencies: `~/.cargo`
- compatible Rust compilation output: `.cache/cargo-target`

Project `.dart_tool`, `.gradle`, and `build` directories remain local because
they contain project-specific state. Reclaim an individual Flutter app's output
with `flutter clean`; do not duplicate or routinely delete the shared caches.

## Toolchain

- Flutter and Dart for five client apps
- Android SDK 36 and Java 17/21 as required by each Gradle project
- Rust stable for the Artiverse backend and duel service
- Python 3/Pillow for store artwork utilities

Godot is no longer required. StackO! is a production Flutter app while retaining
its package ID `id.artivy.stacko` and Play Store signing lineage.

## Cross-repository responsibilities

App privacy/terms links and the root `app-ads.txt` are served by `artivy/`.
When telemetry, ads, accounts, storage, or data collection changes in an app,
update its matching legal page in the same release.

Read each project's `CLAUDE.md` and `PUBLISHING.md` before release work.
