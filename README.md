# artivy-studio

Workspace for the **Artivy** mobile games and the publisher site. This repo holds
the workspace documentation and a bootstrap script — **not** the projects
themselves.

## The projects

| Dir                  | What                                          | Stack                | Remote                                 |
|----------------------|-----------------------------------------------|----------------------|----------------------------------------|
| `wordle/`            | **Kata·Word** — Wordle-style word game        | Flutter · Riverpod   | `github.com/ndri-nr/wordle`            |
| `pawdoku/`           | **Pawdoku** — cat-themed logic puzzle         | Flutter · Provider   | `github.com/ndri-nr/pawdoku`           |
| `stacko/`            | **StackO!** — isometric neon block stacker    | Godot 4.7 · GDScript | `github.com/ndri-nr/stacko`            |
| `artivy/`            | Publisher site incl. every game's legal pages | static HTML · Pages  | `github.com/ndri-nr/artivy`            |
| `ndri-nr.github.io/` | `app-ads.txt` at the domain root, for AdMob   | one text file        | `github.com/ndri-nr/ndri-nr.github.io` |

`ndri-nr.github.io/` is a separate repo and has to be. AdMob takes the domain from
an app's Play listing and crawls `https://<domain>/app-ads.txt` — the root, path
ignored. `artivy/` is a GitHub Pages *project* site served at `/artivy/` and can
never answer for the root, so the file placed there would exist and never be
found. Only a repo named `<user>.github.io` serves that root. It is also the only
public repo besides `artivy/`, which is fine: `app-ads.txt` is a public
declaration by design and the publisher ID in it travels in every ad request.

## Setting up a machine

```bash
git clone https://github.com/ndri-nr/artivy-studio.git
cd artivy-studio
./bootstrap.sh
```

## Why these are not submodules

Each project ships on its own schedule, to its own store listing, with no shared
build, no shared package and no CI that builds them together. Submodules would buy
a consistent snapshot of them all — which nothing here consumes — and charge for it
on every single change: two commits instead of one, a detached HEAD by default, and
a stale pointer whenever the second commit is forgotten.

The one real coupling runs the other way anyway. Each app links to its own privacy
policy and terms **by URL** at runtime:

- `wordle/lib/models/game_config.dart` → `.../artivy/kata_word/*.html`
- `pawdoku/lib/screens/home_screen.dart` → `.../artivy/pawdoku/*.html`
- `stacko/scripts/menu_ui.gd` → `.../artivy/stacko/*.html`

A submodule pointer cannot enforce that: the live site is whatever `artivy/main`
last deployed, not whatever commit a pointer names. What keeps it honest is
remembering to edit the matching page in `artivy/` when a game changes what it
collects — which is written down in `CLAUDE.md`, where it belongs.

If a shared Dart package or a CI job that builds all three games ever appears, that
is the moment to revisit this — as a real monorepo rather than submodules.

## Where the details live

`CLAUDE.md` here covers what spans the workspace: the cross-repo legal-page
coupling, release signing (keystore passwords live in the macOS login Keychain, not
on disk), the toolchain, and which patterns are shared between the games versus
merely similar.

Anything specific to one project is in that project's own `CLAUDE.md` and
`PUBLISHING.md`. Read those before touching it — each has traps that cost real time
to rediscover.
