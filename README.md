# scrolls-releases

Public **release channel** for [scrolls.md](https://github.com/absilutely/scrolls) — the
"filesystem for agents." This repo hosts the published **release assets** (the `scrolls` CLI
binaries and the desktop app installers) plus the **installer scripts** that fetch them.

> This repo is a distribution point only. The CLI and desktop app are **built in the main
> [`absilutely/scrolls`](https://github.com/absilutely/scrolls) repo**; their artifacts are
> uploaded here as GitHub Release assets, per release.

## Install

### macOS / Linux (CLI)

```sh
curl -fsSL https://raw.githubusercontent.com/absilutely/scrolls-releases/main/install.sh | sh
```

Installs the latest `scrolls` binary for your platform to `/usr/local/bin/scrolls`
(or `~/.local/bin/scrolls` if the former isn't writable). Then:

```sh
scrolls --version
```

### Windows (CLI)

```powershell
irm https://raw.githubusercontent.com/absilutely/scrolls-releases/main/install.ps1 | iex
```

Installs `scrolls.exe` to `%LOCALAPPDATA%\scrolls\` and adds it to your user PATH.
Open a new terminal, then:

```powershell
scrolls --version
```

## Downloads

Grab prebuilt artifacts directly from the latest release:

**➡ [github.com/absilutely/scrolls-releases/releases/latest](https://github.com/absilutely/scrolls-releases/releases/latest)**

### Desktop app

| Platform | Asset |
|----------|-------|
| macOS    | `.dmg` |
| Windows  | `.exe` (installer) |
| Linux    | `.AppImage` |

### CLI binaries

| Platform        | Asset                  |
|-----------------|------------------------|
| macOS (Apple)   | `scrolls-darwin-arm64` |
| macOS (Intel)   | `scrolls-darwin-x64`   |
| Linux (x86_64)  | `scrolls-linux-x64`    |
| Linux (arm64)   | `scrolls-linux-arm64`  |
| Windows (x64)   | `scrolls-windows-x64.exe` |

> Assets are published **per release** — the `install.sh` / `install.ps1` one-liners always
> resolve the *latest* release, so they keep working as new versions ship.

## Releasing

Releases are cut by pushing a `v*` tag (e.g. `v0.1.0`). The
[`release.yml`](.github/workflows/release.yml) workflow then creates a GitHub Release for that
tag and uploads everything placed in a `dist/` directory as assets.

The **builds happen upstream** (in `absilutely/scrolls`, or via a manual `dist/` upload here) —
this repo only *publishes*. Place the built artifacts in `dist/` using these exact names so the
installers can resolve them:

**CLI binaries**

- `scrolls-darwin-arm64`
- `scrolls-darwin-x64`
- `scrolls-linux-x64`
- `scrolls-linux-arm64`
- `scrolls-windows-x64.exe`

**Desktop app installers**

- `scrolls-<version>.dmg` (macOS)
- `scrolls-<version>-setup.exe` (Windows)
- `scrolls-<version>.AppImage` (Linux)

Then:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The workflow does the rest.
