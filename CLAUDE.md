# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`artivy-studio` is a **workspace folder, not a repo** — it holds four
independent git repos, each with its own remote and `main` branch. There is no
root git, no root build, no shared package. Always work inside one subproject.

| Dir        | What                                          | Remote                          |
|------------|-----------------------------------------------|---------------------------------|
| `wordle/`  | **Kata·Word** — Flutter Wordle-style game     | `github.com/ndri-nr/wordle`     |
| `pawdoku/` | **Pawdoku** — Flutter cat logic-puzzle game   | `github.com/ndri-nr/pawdoku`    |
| `stacko/`  | **StackO!** — Godot 4.7 isometric block stacker | `github.com/ndri-nr/stacko`   |
| `artivy/`  | Publisher website (static HTML, GitHub Pages) | `github.com/ndri-nr/artivy`     |

`wordle/CLAUDE.md`, `pawdoku/CLAUDE.md` and `stacko/CLAUDE.md` are the
authoritative per-project guides (architecture, gotchas, hidden features).
**Read the relevant one before touching that project.** Each also has a
`PUBLISHING.md` with the Play Store release flow.

**StackO! is Godot/GDScript, not Flutter.** Nothing about the Flutter toolchain,
`pubspec.yaml`, widgets or Dart applies there, and its build has its own traps —
see `stacko/PUBLISHING.md` §2 before attempting an Android export.

## The one cross-repo coupling

The apps' in-app Privacy/Terms links are hard-coded URLs into the **`artivy/`
Pages site**:

- `wordle/lib/models/game_config.dart` → `.../artivy/kata_word/*.html`
- `pawdoku/lib/screens/home_screen.dart` → `.../artivy/pawdoku/*.html`
- `stacko/scripts/menu_ui.gd` (`PRIVACY_URL`/`TERMS_URL`) → `.../artivy/stacko/*.html`

Site path for Kata·Word is `kata_word/`, not `wordle/`. Changing a game's
data collection, ads, or purchases means editing the matching legal page in
`artivy/` too, or the store listing goes stale. Renaming/moving a page in
`artivy/` breaks a live in-app link.

The three games' policies are **not interchangeable**: the Flutter pair ships
Firebase Crashlytics and Kata·Word also ships Analytics, while StackO! has
neither, so its page must not be copied from theirs. StackO! pointed at
Kata·Word's page for a while, which would have failed review — Play checks that
the policy describes the app it is attached to.

## Commands

Flutter projects (`wordle/`, `pawdoku/`) — run from inside the project dir:

```bash
flutter pub get
flutter analyze                                   # keep clean
flutter test                                      # all tests
flutter test test/date_seed_test.dart             # single file
flutter test --plain-name "unique"                # single test by name
flutter run                                       # device/emulator
flutter run -d chrome                             # quick UI check (ads/Firebase no-op on web)
flutter build appbundle --release                 # Play Store artifact
```

Wordle only: `flutter gen-l10n` after editing `lib/l10n/*.arb` (generated
`app_localizations*.dart` is committed).

Godot project (`stacko/`) — `godot` is the Homebrew cask, on `PATH`:

```bash
godot --path .                                       # play it
godot --path . --headless --editor --quit-after 400  # import, surface parse errors
godot --path . --headless --script tools/smoke_test.gd   # the real regression test
godot --path . --script tools/screenshot.gd -- <dir>     # needs a display
```

Website (`artivy/`): no build step, no deps. Open `index.html` directly, or
`python3 -m http.server`. Pushing to `main` deploys the whole repo to GitHub
Pages via `.github/workflows/static.yml`.

Toolchain here is Homebrew Flutter (`/opt/homebrew/bin/flutter`) and Homebrew
Godot (`/opt/homebrew/bin/godot`). Android builds need **JDK 21**
(`/usr/libexec/java_home -v 21`) — the default `JAVA_HOME` on this Mac is
Corretto 24, and Gradle fails inside its daemon rather than blaming Java.

Gradle versions are deliberately **not** unified: wordle is on 9.1.0 (AGP 9.0.1),
pawdoku on 8.14 (AGP 8.11.1), and stacko on 8.11.1 because Godot's Android build
template pins it — that wrapper is regenerated from `android_source.zip` and is
not ours to edit.

## Release signing (all three games)

Each app has its own upload key in `~/key-store/<game>-upload.jks`, outside every
repo, and **no password is stored on disk**. Passwords live in the macOS login
Keychain and are read at build time:

- **wordle / pawdoku** — `android/app/build.gradle.kts` shells out to `security
  find-generic-password -s <game>-upload-keystore -w`. `android/key.properties`
  (gitignored) holds only `keyAlias` and `storeFile`. A missing Keychain item
  **fails the build** on purpose; falling back to the debug key would produce a
  bundle Play rejects only after upload, by certificate fingerprint.
- **stacko** — Godot reads `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` / `_USER` /
  `_PASSWORD` from the environment; fill the last one from the Keychain the same
  way. `export_presets.cfg` is tracked, which is exactly why the password must
  never be typed into it.

Store one copy of each password off this machine as well. The Keychain dies with
the laptop, and a `.jks` without its password is as useless as the password
without the file.

## Shared shape of the games

The two Flutter games were built to the same playbook, so a pattern learned in one
usually transfers — but they are **separate codebases with different stacks**, and
StackO! is a third stack again. Never import or copy-reference across them; port
the idea, not the file.

- Android ids: `id.artivy.wordle`, `id.artivy.pawdoku`, `id.artivy.stacko`.
  Publisher "Artivy".
- Fully offline gameplay. Persistence is `shared_preferences` behind a typed
  wrapper (`GameStorage`/`Prefs` vs `Storage`) in the Flutter pair, and a
  `ConfigFile` behind `Save` (`user://stacko.cfg`) in StackO! — never touch raw
  prefs keys or config sections outside those wrappers.
- State: **wordle = Riverpod**, **pawdoku = Provider/ChangeNotifier**, **stacko =
  autoload singletons** (`Save`, `Themes`, `Modes`, `Audio`, `Ads`).
- Deterministic daily challenge seeded by date in the Flutter pair; **streaks are
  recomputed from won-day history**, never incremented in place, so back-filling
  past days counts. StackO! has no daily: its meta is per-mode best scores and a
  local rank tier, which is **not** a leaderboard and says so on screen.
- Consumable assists with the same payment priority: owned token → coins →
  watch-an-ad. Never free.
- Currency + store + themes: coins in the Flutter pair, **gems** in StackO!
  (earned by playing, spent in the shop, no real-money purchases anywhere).
  **Persisted trophy ids, store item ids and theme ids are shipped data — never
  rename one.** StackO! also throws its save away on a `Save.FORMAT` bump rather
  than migrating, so bumping it is a deliberate wipe.
- Hidden long-press switches in all three, and they do **different** things: the
  Flutter pair grant coins after a 60-second hold (`kCheatHoldSeconds`), StackO!
  toggles ads for that device after 7 seconds on the Version row
  (`AD_HOLD_SECONDS`). The long holds and the tap-vs-hold suppression are
  load-bearing — do not "fix" them.
- AdMob unit ids are still Google **test** ids in all three; see each
  `PUBLISHING.md`.
- Crash/analytics differ, and the privacy pages depend on it: wordle has
  Crashlytics + Analytics, pawdoku Crashlytics only, **stacko neither**.

## Conventions

- Match the surrounding style; keep `flutter analyze` clean. In stacko, tabs,
  `snake_case`, and comments that explain *why* — run the harnesses in
  `stacko/tools/` rather than judging a change by eye.
- Commits: Conventional-ish (`feat(themes):`, `docs(pawdoku):`), explain the
  *why*. Commit in the subproject repo, not the workspace root.
- Repos are private, so `google-services.json` is committed; keystores,
  `key.properties`, and `stacko/android/` (the generated Gradle tree) are
  git-ignored.
- `// ponytail:` comments mark deliberate simplifications — read before
  "improving" one.
