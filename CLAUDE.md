# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`artivy-studio` holds several **independent** git repos, each with its own remote
and `main` branch. No root build, no shared package. Always work inside one
subproject, and commit there — never at the root.

The root is itself a small git repo, but a **docs-only** one: it tracks
`README.md`, `CLAUDE.md`, `bootstrap.sh` and `.gitignore`, nothing else. Every
subproject directory is gitignored so git cannot record it as a half-made
gitlink. `bootstrap.sh` clones them on a fresh machine and deliberately never
pulls — each may hold work in progress.

| Dir                  | What                                            | Remote                                 |
|----------------------|-------------------------------------------------|----------------------------------------|
| `wordle/`            | **Kata·Word** — Flutter Wordle-style game       | `github.com/ndri-nr/wordle`            |
| `pawdoku/`           | **Pawdoku** — Flutter cat logic-puzzle game     | `github.com/ndri-nr/pawdoku`           |
| `stacko/`            | **StackO!** — Godot 4.7 isometric block stacker | `github.com/ndri-nr/stacko`            |
| `2048/`              | **2048** — native Android (Java) sliding-tile puzzle | `github.com/ndri-nr/2048`          |
| `artivy/`            | Publisher website (static HTML, GitHub Pages)   | `github.com/ndri-nr/artivy`            |
| `ndri-nr.github.io/` | `app-ads.txt` at the domain root, for AdMob     | `github.com/ndri-nr/ndri-nr.github.io` |

**Only Pawdoku is on Play production** (as of 2026-08-14; Kata·Word and StackO!
are not released yet). That decides who needs a version bump: a release build of
a **shipped** app must raise `version:` in `pubspec.yaml` — name *and* build
number — because Play rejects a versionCode it has already seen. An app that has
never shipped can rebuild at the same version indefinitely, so don't bump wordle
or stacko unless asked. Re-check this line when another game goes live.

**`app-ads.txt` has to live in its own repo, not in `artivy/`.** AdMob takes the
domain from an app's Play listing and crawls `https://<domain>/app-ads.txt` — the
root, with the listing URL's path ignored. `artivy/` is a Pages *project* site
served at `/artivy/`, so it can never answer for the root; the file placed there
would exist and never be crawled. Only a repo named `<user>.github.io` serves it.

The file belongs to the **domain**, not to an app: one line authorises the
publisher ID for every app whose listing points at this domain, so Kata·Word and
StackO! need nothing added when their turn comes. The per-app step is on the store
side — each listing's **Website** field must carry this domain, and an empty one
fails verification with a message that blames the file instead.

`wordle/CLAUDE.md`, `pawdoku/CLAUDE.md`, `stacko/CLAUDE.md` and `2048/CLAUDE.md`
are the authoritative per-project guides (architecture, gotchas, hidden features).
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

**2048 is the exception: it has no in-app legal links yet.** Its pages at
`artivy/2048/` exist for the Play listing's Privacy-policy field; nothing in the
app opens them, so there is no URL in the app to break. Wiring a link in later
means the same coupling as the other three.

Site path for Kata·Word is `kata_word/`, not `wordle/`. Changing a game's
data collection, ads, or purchases means editing the matching legal page in
`artivy/` too, or the store listing goes stale. Renaming/moving a page in
`artivy/` breaks a live in-app link.

The games' policies are **not interchangeable**: the Flutter pair ships
Firebase Crashlytics and Kata·Word also ships Analytics, while StackO! ships
Analytics + Crashlytics **plus `firebase-crashlytics-ndk`**, which neither Flutter
app has any use for — so no page here may be copied from another. StackO! pointed at
Kata·Word's page for a while, which would have failed review — Play checks that
the policy describes the app it is attached to.

2048 differs again, and in a way that matters more than the SDK list: its
Analytics events carry **gameplay figures** (run score, highest tile, whether the
run passed 2048, chosen language) rather than aggregate screen views, and its
SharedPreferences file rides Android's `allowBackup`, so scores can reach the
player's Google account. Its page says both. It also has **no UMP consent flow**,
unlike Pawdoku and StackO! — so its page must not promise a consent screen, and
an EEA release needs that flow built first.

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

Native Android project (`2048/`) — Gradle wrapper only, no Flutter, no Godot:

```bash
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties  # once per machine
./gradlew :app:assembleDebug                                 # debug APK
./gradlew :app:testDebugUnitTest                             # JVM unit tests
./gradlew :app:bundleRelease                                 # Play artifact (needs the key)
```

Wrapper is Gradle **9.1.0**, AGP 8.13.0, compileSdk 36, minSdk 26, Java 17 — a
fourth toolchain, unrelated to the two above. `local.properties` is gitignored, so
a fresh clone cannot configure until it exists.

Website (`artivy/`): no build step, no deps. Open `index.html` directly, or
`python3 -m http.server`. Pushing to `main` deploys the whole repo to GitHub
Pages via `.github/workflows/static.yml`.

Toolchain here is Homebrew Flutter (`/opt/homebrew/bin/flutter`) and Homebrew
Godot (`/opt/homebrew/bin/godot`). Android builds need **JDK 21**
(`/usr/libexec/java_home -v 21`) — the default `JAVA_HOME` on this Mac is
Corretto 24, and Gradle fails inside its daemon rather than blaming Java.

Both Flutter apps are on **Gradle 9.1.0 + AGP 9.0.1 + Kotlin 2.3.20**, which keeps
one cached Gradle distribution instead of two. `google_mobile_ads` must stay **>= 9**
in both: older majors fail Gradle 9 configuration with `unknown property 'all' for
configuration container`, so that plugin sets the floor under the whole toolchain.

StackO! stays on Gradle **8.11.1** and cannot be unified — Godot generates that
wrapper from `android_source.zip` into the gitignored `stacko/android/` tree, so the
version belongs to the engine and any edit is erased by the next
`--install-android-build-template`.

## Release signing (all four games)

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
- **2048** — same Keychain shape as the Flutter pair (`app/build.gradle.kts`
  shells out to `security find-generic-password -s puzzle2048-upload-keystore -w`,
  `key.properties` at the repo root holds only alias and path). Create the key,
  the Keychain item and the properties file in one go with `./tools/upload_key.sh`,
  which also prints the SHA-1/SHA-256 fingerprints Firebase wants. It replaced a
  **debug-keystore fallback** in `signingConfigs["release"]`: that produced an
  installable release APK, and a bundle Play would accept once and then never let
  you update, since the upload certificate can't change.

Store one copy of each password off this machine as well. The Keychain dies with
the laptop, and a `.jks` without its password is as useless as the password
without the file.

## Shared shape of the games

The two Flutter games were built to the same playbook, so a pattern learned in one
usually transfers — but they are **separate codebases with different stacks**, and
StackO! is a third stack again. Never import or copy-reference across them; port
the idea, not the file.

- Android ids: `id.artivy.wordle`, `id.artivy.pawdoku`, `id.artivy.stacko`,
  `id.artivy.puzzle2048`. Publisher "Artivy".
- **2048 is outside this shared shape.** It is native Java, has no coins, no
  store, no themes, no daily challenge, no hidden long-press, and no rewarded ad —
  only a banner and an interstitial. Do not go looking for the patterns below in
  it; `2048/CLAUDE.md` describes what it actually has.
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
- AdMob unit ids: **pawdoku is live** (real units under publisher
  `pub-8668013395284480`, since 1.0.1+3), wordle and stacko still carry Google's
  **test** ids — `_testInterstitial` etc. in `wordle/lib/services/ad_service.dart`,
  `USE_TEST_ADS = true` in `stacko/scripts/ads.gd`. See each `PUBLISHING.md`.
- **Advertising ID: all three answer "yes" on Play.** `google_mobile_ads` (and the
  Godot AdMob plugin) add `com.google.android.gms.permission.AD_ID`, Firebase
  Analytics adds `android.permission.AD_ID`, and Play refuses to let the question
  disagree with the manifest. Removing the permission only costs personalised ads.
- Crash/analytics differ, and the privacy pages depend on it: wordle has
  Crashlytics + Analytics, pawdoku Crashlytics only, **stacko Crashlytics +
  Analytics + the NDK artifact** (it is a native game, so Java-only crash
  reporting would record nothing). In stacko the wiring is not a dependency line
  but `tools/patch_android_firebase.py`, replayed after every
  `--install-android-build-template`.

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
