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
| `rekta/`             | **Rekta** — native Android (Java) Shikaku puzzle | `github.com/ndri-nr/rekta`             |
| `parkeer/`           | **Parkeer!** — Godot 4 parking-jam prototype      | *no remote yet*                        |
| `artivy/`            | Publisher website (static HTML, GitHub Pages)   | `github.com/ndri-nr/artivy`            |
| `ndri-nr.github.io/` | `app-ads.txt` at the domain root, for AdMob     | `github.com/ndri-nr/ndri-nr.github.io` |

`parkeer/` is a **local prototype with no remote**, so `bootstrap.sh` does not
list it and a fresh machine will not have it. Give it a remote before adding the
line, or the script fails for every repo after it. It is a fifth toolchain in
name only — Godot 4.7 like StackO!, but its own project with no menu, save, ads
or signing yet. `parkeer/CLAUDE.md` says what is deliberately missing.

**Pawdoku is on Play production; Kata·Word and StackO! are in closed testing**
(as of 2026-08-15). All three need a version bump before any new release build.

A versionCode is unique per app across **every** Play track, not just
production — a bundle uploaded to closed testing burns that number exactly as a
production release does. So "has it shipped to production yet" is the wrong
question; the question is "has anything ever been uploaded for it". Raise
`version:` in `pubspec.yaml` — name *and* build number — for Pawdoku, Kata·Word
and StackO!. Only 2048 and Pawkour can rebuild at the same version, and only
until their first upload.

Games sitting in testing are finished games, not stalled ones. Don't read
anything about what this developer can or cannot finish from which titles are on
production — that inference has been drawn once here, and it was wrong.

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

`wordle/CLAUDE.md`, `pawdoku/CLAUDE.md`, `stacko/CLAUDE.md`, `2048/CLAUDE.md` and
`rekta/CLAUDE.md`
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

- `2048/app/src/main/res/values/strings.xml` (`privacy_policy_url`/`terms_url`) →
  `.../artivy/2048/*.html`, opened from its Settings panel.
- `rekta/app/src/main/res/values/strings.xml` (same two keys) →
  `.../artivy/rekta/*.html`, also from its Settings panel.

Site path for Kata·Word is `kata_word/`, not `wordle/`. Changing a game's
data collection, ads, or purchases means editing the matching legal page in
`artivy/` too, or the store listing goes stale. Renaming/moving a page in
`artivy/` breaks a live in-app link.

**Those URLs have no `games/` in them, and the source files do.** In the repo the
pages live at `artivy/games/<slug>/`; the Pages workflow copies `games/*` back to
the site root before uploading, so the published paths stay
`/artivy/<slug>/*.html` — exactly what five shipped binaries ask for. Edit the
page under `artivy/games/`, never assume the repo path is the URL path, and do
not delete the flatten step in `artivy/.github/workflows/static.yml`: it is the
only thing keeping those links alive.

The games' policies are **not interchangeable**: the Flutter pair ships
Firebase Crashlytics and Kata·Word also ships Analytics, while StackO! ships
Analytics + Crashlytics **plus `firebase-crashlytics-ndk`**, which neither Flutter
app has any use for — so no page here may be copied from another. StackO! pointed at
Kata·Word's page for a while, which would have failed review — Play checks that
the policy describes the app it is attached to.

**Rekta and 2048 both exclude their save file from Android backup, and both pages
now say so.** Rekta excludes its progress file; 2048 excludes `artivy_2048.xml`
from cloud-backup *and* device-transfer (`res/xml/backup_rules.xml`,
`res/xml/data_extraction_rules.xml`), because that one file carries the hidden ads
switch alongside the scores and a stale switch from a day-old snapshot is the bug
Pawdoku shipped once. 2048's page described the opposite until 2026-08-19 — it
promised players backup would carry their scores — so treat a claim here about
backup as something to check against those two XML files, not as settled. Rekta's page also lists its
analytics events by name — level start/end with level, grid size, seconds and
hints — so **adding an event to `rekta/.../Telemetry.java` makes the published
policy wrong until that page is edited too.** Copying either page onto the other
would misstate both.

2048 differs again, and in a way that matters more than the SDK list: its
Analytics events carry **gameplay figures** (run score, highest tile, whether the
run passed 2048, chosen language) rather than aggregate screen views. Its page says
so. It *does* have a UMP consent flow — `Consent.java`, gathered on the splash —
which is why its page describes the consent step and the Settings row that reopens
it.

**2048's banner is on its Settings screen, not its board, and its interstitial is
timed.** `SettingsActivity` owns the app's only `AdView`; `activity_main.xml` has
none, and putting one back on the board undoes a deliberate choice — a 2048 run is
long, and a fixed advert under a grid someone stares at for all of it is what makes
a game feel cheap. The interstitial fires when a new game starts after a game over
and only if that run lasted 60s (`MIN_RUN_MS_FOR_INTERSTITIAL`), replacing a
count-based rule that charged a player two twenty-second losses. Rekta has the same
banner arrangement; the other three do not.

## The browser builds

Each game is getting a playable web version on the Pages site, at
`artivy/games/<slug>/play.html` in the repo and `/artivy/<slug>/play.html` once
the deploy flattens `games/` away. **All five are built.**

These share **no code with the Android repos** and are not ports of them. The
rules were rewritten in JavaScript from what each game does; the Dart, Java and
GDScript stay where they are. Nothing in `artivy/` imports from a game repo and
nothing ever should — the site deploys on its own, and a shared file would tie a
Play release to a website push.

No framework, no bundler, no `package.json`. Plain ES modules served as-is, which
is the whole reason this can live in a repo whose deploy is "copy the files".
Adding a build step here means the site can no longer be checked by opening it.

- `artivy/js/storage.js` — the save wrapper every game uses. Namespaced
  `artivy.<slug>.*`, and it survives the three things that actually happen:
  storage that throws (private windows), a full quota, and a corrupt value. When
  it cannot persist it falls back to memory so the game still runs, and
  `isPersistent()` is how a page knows to warn the player.
- `artivy/css/play.css` — the shared page shell. Board sizing, the landscape
  phone layout, the ad slot.
- `artivy/games/<slug>/model.js` — the rules, **with no DOM in them**. That is
  what makes `selftest.html` in the same folder possible: open it and it prints
  pass/fail lines for the rules that would silently cost a player their game.
  Run it after touching a model.

**The board's size is a declared constant, not a measurement.**
`--play-chrome-stacked` is the height of everything that is not the board, and the
board is `min(max, 100%, (100dvh - var(--play-chrome)) * var(--board-ratio))`. A
game overrides `--play-chrome-stacked` for its own panel; the landscape media query
sets `--play-chrome` itself, so overriding one never breaks the other.
`--board-ratio` is width ÷ height, left at 1 by 2048 and set to `cols/rows` by
Rekta's portrait grids. An earlier version measured the
layout from JavaScript and set the size from that; it was wrong on load, because
the web font had not swapped in yet, and wrong again on resize, because it read a
viewport that was still moving. JavaScript now only reads the board's final size
through a `ResizeObserver` to place tiles. Do not reintroduce the measuring
version — a constant that is slightly generous costs a slightly smaller board,
which is a far cheaper way to be wrong.

`dvh`, never `vh`: mobile browser chrome slides away as the page scrolls, and
`vh` measures the taller state, so a `vh`-sized board is clipped for exactly as
long as the toolbar is showing.

**A play page and its script are cached separately, so bump `?v=` when a change
spans both.** Every play page loads its own CSS and JS as `play.js?v=N`. GitHub
Pages serves `cache-control: max-age=600`, which means a browser can hold a new
`play.html` beside a `play.js` from ten minutes ago — and when the change removed
a button the old script still reached for at boot, the module threw and the board
came up blank. Safari holds that pair longest. The version makes them
inseparable: whichever page a browser has, it asks for the assets that shipped
with it. Bump it on any change that alters what the JS expects the HTML to
contain.

A play page must **not** load `js/main.js`. That is the home page's Three.js
particle field — a continuous repaint competing with the game for frames.

**AdSense is wired, one unit per game, and the unit's size is load-bearing.** Each
game has its own `data-ad-slot`, used on both its `play.html` and its `index.html`,
so reports stay per-game — a shared unit merges those figures and they cannot be
split afterwards.

On a play page the slot is a **fixed 100×100%**, not the `data-ad-format="auto"`
AdSense hands you. Auto lets Google choose the height at runtime, and this layout
cannot survive that: the board is `100dvh - var(--play-chrome)`, that constant is
declared by hand, and it has exactly 100px budgeted for the advert. One arriving
280px tall pushes the page off the bottom of the screen with nothing in the layout
able to see it coming. About pages use `auto` freely — nothing there is sized from
a constant.

**A hidden slot must not carry an `<ins>` at all.** `adsbygoogle.push({})` does not
fill the slot nearest the call; it fills the next uninitialised `<ins>` in document
order. Side rails written into the markup and merely hidden by CSS therefore stole
the banner's push, failed on `availableWidth=0`, and left the banner unfilled. The
rails build their `<ins>` from script only when the media query matches, and the
banner's push is guarded on `offsetWidth > 0` because landscape phones hide it.

Wide screens carry two 160×600 rails as well, absolutely positioned against a
wrapper — never flex items beside the stage, because the board's `100%` resolves
against the stage and making it content-sized would move the number the whole
sizing model rests on. 1024px on a play page, 1280px on an about page.

Privacy and terms pages carry the loader script but **no ad unit**: thin pages are
what AdSense's low-value content policy is about. Nothing goes within 32px of a
board — a missed swipe landing on an advert is an accidental click, and enough of
those close a publisher account. Auto ads must stay **off**: Google would insert
adverts wherever it liked, including into the height `--play-chrome` claims to
know.

**The browser builds are the games, not the meta around them.** No coins, no
store, no trophies, no themes, no hints and no daily challenge — Kata·Word's
daily word, Pawdoku's timed daily and Rekta's rewarded hint are all absent, and
each game's privacy page says so explicitly, because the app's page describes
purchases and rewarded adverts that do not exist here.

Kata·Word's word lists under `games/kata_word/words/` are still copies of the
app's `assets/words/`, and that is the one place data crosses over from a game
repo deliberately. They are the output of a filtering pipeline with real
judgement in it — dictionary consensus for Indonesian, capitalisation as a
proper-noun detector for English — and rebuilding it in JavaScript would produce
a worse list. Only `answers` and `guesses` are here; `daily_*.txt` went with the
daily challenge.

Rekta is the opposite case and for a good reason: matching its levels would mean
reproducing `java.util.Random` bit for bit, which buys a player nothing.

Each game's privacy page has to describe the browser build separately from the
app: local storage rather than SharedPreferences, no Android backup, no analytics
and no crash reporting — and **one AdSense banner**, which all five pages now
spell out: a plain display advert, not rewarded, no interstitial, loaded once and
never refreshed. Those five sentences are the reason the advert markup and the
privacy edit have to ship in the same commit, never one after the other.

**StackO! is the only one with a render loop, and it is a canvas.** The Android
build is a real 3D scene in Godot; here the tower is flat quads under an
isometric projection, which is all that camera ever showed — the angle never
moves and nothing rotates, so three faces a block is the whole of it. No WebGL
and no 3D library. Two things in `play.js` are load-bearing: the fixed timestep,
without which the slab travels twice as fast on a 120Hz phone as on a 60Hz
laptop, and the ceiling on catch-up, without which returning to a backgrounded
tab runs thousands of steps at once and the slab teleports.

**Pawdoku's tap model is not the obvious one, and `pawdoku/CLAUDE.md` describes
it wrongly.** That file says `tap()` cycles empty→cat→blocked→empty. The code in
`state/game_controller.dart` and `widgets/board_grid.dart` does something else: a
tap toggles the player's own X, a second tap on the same cell within 200ms
*summons* a cat, a long press summons directly, and dragging paints X. A summoned
cat is judged against `puzzle.solution` — **not** against `checkPlacement` — so a
cell that breaks no rule yet is still wrong, costs a life, and becomes a
permanent locked cross. The web build was written from that doc line first and
had to be redone; its `selftest.html` now pins each of those rules so the same
misreading cannot happen twice.

**Pawdoku's generator is fast only because the solver searches the smallest
region first.** Proving a board has no *second* solution means exhausting the
search tree, and that is where the whole cost sits. In region order a 9×9 took
~290ms to generate — enough to stall a tap, and enough that a worker thread
looked necessary. Ordering by fewest candidate cells first took it to ~3ms, so
there is no worker and no build step. `selftest.html` times it and fails below
250ms, which is the guard against someone quietly removing that sort.

**Back buttons are links, not `history.back()`.** A game page goes up to the site
index, a legal page up to its own game. The old version sent a player wherever
they happened to arrive from, which for a policy link opened out of an app's
Settings screen was nowhere at all.

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

Native Android projects (`2048/`, `rekta/`) — Gradle wrapper only, no Flutter, no
Godot. Same commands in either:

```bash
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties  # once per machine
./gradlew :app:assembleDebug                                 # debug APK
./gradlew :app:testDebugUnitTest                             # JVM unit tests
./gradlew :app:bundleRelease                                 # Play artifact (needs the key)
```

Wrapper is Gradle **9.1.0**, AGP 8.13.0, compileSdk 36, minSdk 26, Java 17 — a
fourth toolchain, unrelated to the two above. `local.properties` is gitignored, so
a fresh clone cannot configure until it exists.

Rekta carries Firebase Analytics + Crashlytics, same shape as 2048 — plugins from
the same version catalog, `google-services.json` committed (private repo), and one
`Telemetry.java` holding every call. Its debug variant has **no
`applicationIdSuffix`** for the same reason 2048's does not: the file carries a
client for the release id only, and the plugin fails the build on a variant it
cannot match.

Website (`artivy/`): no build step, no deps. Open `index.html` directly, or
`python3 -m http.server`. Pushing to `main` deploys the whole repo to GitHub
Pages via `.github/workflows/static.yml`.

The home page and the game pages link each other as if the games sat at the site
root, because after the workflow's flatten step they do. Served straight from the
repo those links 404. To preview the real layout, flatten into a scratch copy:

```bash
rm -rf /tmp/artivy-preview && cp -R artivy /tmp/artivy-preview \
  && (cd /tmp/artivy-preview && cp -R games/. . && rm -rf games .git) \
  && python3 -m http.server -d /tmp/artivy-preview
```

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

## Release signing (all five games)

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
- **rekta** — identical to 2048, with `rekta-upload-keystore` as the service name
  and its own `./tools/upload_key.sh`, which also prints the SHA-1/SHA-256 the
  Firebase console wants.

Store one copy of each password off this machine as well. The Keychain dies with
the laptop, and a `.jks` without its password is as useless as the password
without the file.

## Shared shape of the games

The two Flutter games were built to the same playbook, so a pattern learned in one
usually transfers — but they are **separate codebases with different stacks**, and
StackO! is a third stack again. Never import or copy-reference across them; port
the idea, not the file.

- Android ids: `id.artivy.wordle`, `id.artivy.pawdoku`, `id.artivy.stacko`,
  `id.artivy.puzzle2048`, `id.artivy.rekta`. Publisher "Artivy".
- **2048 and Rekta are outside this shared shape.** Both are native Java with no
  coins, no store, no themes, no daily challenge and no rewarded ad — only a banner
  and an interstitial. Do not go looking for the patterns below in them;
  `2048/CLAUDE.md` and `rekta/CLAUDE.md` describe what they actually have.
  Rekta does keep one shared idea: a hidden **7-second** hold on the Settings
  version line that turns ads off for screenshots, the same shape as StackO!'s.
- **Rekta's levels are generated from their number**, not stored — the run is
  endless and level *n* is the same grid everywhere. Editing its generator
  renumbers every level for players mid-run; treat that as a content change.
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
- **UMP consent: all five gather it, only four can reopen it.** Kata·Word, 2048,
  Rekta and
  StackO! ask before the first ad request *and* expose an "Ad privacy options" entry
  where Google reports it as required. **Pawdoku gathers consent but offers no way
  back in** (`_gatherConsent` in `lib/services/ad_service.dart`, no Settings entry) —
  Google's EU user consent policy requires that entry point for users who were asked,
  and Pawdoku is the one app already on production. Fix that before any EEA push.
- **Play in-app updates: all five, and the flow is IMMEDIATE.** When a newer build
  is live the store's own full-screen sheet appears; Play owns the UI, the download
  and the relaunch, so no game draws an update dialog of its own and none has a
  "restart now" prompt to manage. The Flutter pair go through `in_app_update` (one
  `_checkForUpdate()` in `main.dart`, scheduled at `Priority.idle` beside the other
  init); the native pair have `Updates.java` next to `Consent.java`; StackO! gets
  `tools/android/Updates.java` copied into the generated tree by
  `tools/patch_android.py`, because the flow has to start from the Android activity
  and Godot exposes no binding for it.
  **`check()` belongs in `onCreate`, `resume()` in `onResume`** — the split is the
  whole design. Offering the sheet from `onResume` re-offers it the instant a player
  declines and returns, which is a loop with no way out; `resume()` only re-enters a
  download the player already accepted and that was interrupted.
  **None of it is visible on a build you can make locally.** A sideload, a debug APK
  or an emulator gets `ERROR_APP_NOT_OWNED` and the check is a silent no-op, so
  "nothing happened" is not evidence of a wiring mistake. Play's internal app sharing
  is the only way to see it before release.
  Nothing was added to the privacy pages for it: the API reports no player data and
  runs inside the Play Store app, which every page already covers as the install
  source.
- **Advertising ID: every one of them answers "yes" on Play.** `google_mobile_ads`
  (and the Godot AdMob plugin, and `play-services-ads` in the two native apps) add
  `com.google.android.gms.permission.AD_ID`, Firebase
  Analytics adds `android.permission.AD_ID`, and Play refuses to let the question
  disagree with the manifest. Removing the permission only costs personalised ads.
- Crash/analytics differ, and the privacy pages depend on it: wordle has
  Crashlytics + Analytics, pawdoku Crashlytics only, 2048 and rekta Crashlytics +
  Analytics, **stacko Crashlytics + Analytics + the NDK artifact** (it is a native
  game, so Java-only crash reporting would record nothing). In stacko the wiring is
  not a dependency line but `tools/patch_android.py`, replayed after every
  `--install-android-build-template`.
  2048 and rekta each keep every Firebase call in a single `Telemetry.java`, and
  both of their privacy pages enumerate the events by name — which is what makes
  "edit the page when you add an event" checkable rather than aspirational.

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
