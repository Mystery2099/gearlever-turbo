# gearlever-turbo

Parallel update accelerator companion for [GearLever](https://github.com/mijorus/gearlever) (AppImage manager), powered by [aria2](https://aria2.github.io/).

**This is not a fork or replacement for GearLever.** GearLever stays in charge of integration, desktop files, icons, and configuration. `gearlever-turbo` only does one job: discover every managed AppImage from GearLever’s own data, check for updates concurrently, and download them fast.

> **Note:** This project was written by AI.

## What it does

1. **Reads GearLever metadata** — Parses `gearlever.conf` and legacy `apps.json` (including custom update URLs set in the GearLever UI). Zero separate configuration.
2. **Resolves updates in parallel** — Checks GitHub / Codeberg / Forgejo / GitLab / static HTTP sources concurrently.
3. **Downloads with aria2** — Hands pending full downloads to `aria2c` in one batch (multiple connections per server + parallel downloads).
4. **Respects GearLever’s world** — Replaces AppImages at the same paths GearLever already uses (desktop entries keep working). After a successful run, GearLever’s size/hash checks should report up to date.
5. **Routes zsync apps** — AppImages with embedded `.upd_info` (AppImageSpec zsync) use `appimageupdatetool` for delta updates when available.

## Requirements

| Dependency | Required | Purpose |
|---|---|---|
| Python 3.10+ | yes | Runtime (stdlib only — no pip packages) |
| [GearLever](https://flathub.org/apps/it.mijorus.gearlever) | yes | Source of truth for managed AppImages |
| `aria2c` | yes (for full downloads) | Parallel HTTP downloads |
| `appimageupdatetool` | optional | Delta updates for embedded zsync AppImages |
| `readelf` (binutils) | optional | Detect embedded `.upd_info` |

```bash
# Debian/Ubuntu
sudo apt install aria2 binutils
# Optional delta updates:
#   install appimageupdatetool from your distro or AppImageUpdate releases
```

## Install

```bash
git clone https://github.com/mystery/gearlever-turbo.git
cd gearlever-turbo
chmod +x gearlever-turbo
sudo ln -s "$(pwd)/gearlever-turbo" /usr/local/bin/gearlever-turbo
# or keep it somewhere on your PATH / call it by path
```

## Usage

```bash
gearlever-turbo              # Check and update everything
gearlever-turbo --dry-run    # Show what would be updated
gearlever-turbo --quiet      # Quiet mode for cron / systemd timers
gearlever-turbo --jobs 8 --connections 16
gearlever-turbo --help
```

| Flag | Description |
|---|---|
| `--dry-run` | Resolve and list updates; download nothing |
| `--quiet` / `-q` | Suppress progress; errors still go to stderr |
| `--jobs` / `-j` | Parallel resolve workers and concurrent aria2 downloads (default: 4) |
| `--connections` / `-x` | aria2 connections per server (default: 16) |
| `--config-dir DIR` | Override GearLever config directory |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Success (including “nothing to do”) |
| `1` | Partial failure (some apps failed to resolve or install) |
| `2` | Setup problem (missing GearLever data, missing `aria2c`, bad flags) |

### Scheduled updates

**cron** (user crontab):

```cron
# Every day at 04:30
30 4 * * * /usr/local/bin/gearlever-turbo --quiet
```

**systemd user timer** — `~/.config/systemd/user/gearlever-turbo.service`:

```ini
[Unit]
Description=Parallel GearLever AppImage updates

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gearlever-turbo --quiet
```

`~/.config/systemd/user/gearlever-turbo.timer`:

```ini
[Unit]
Description=Daily gearlever-turbo run

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl --user enable --now gearlever-turbo.timer
```

## How it finds GearLever data

Searches, in order:

1. `~/.var/app/it.mijorus.gearlever/config/` (Flatpak — usual case)
2. `$XDG_CONFIG_HOME/` then `~/.config/` (native installs)

Expected files:

- **`gearlever.conf`** (primary) — INI sections `[app.<md5(file_path)>]` with `name` / `file_path`, and `[app.<hash>.update_manager]` with `manager=` plus updater settings (`repo`, `repo_filename`, `url`, …).
- **`apps.json`** (legacy v1) — optional; used when the INI update section has no `manager` yet (custom URLs / migrated configs).

Embedded update metadata is read from each AppImage’s ELF `.upd_info` section (same idea as GearLever’s `UpdateManagerChecker`), e.g.:

```text
gh-releases-zsync|owner|repo|latest|App-*-x86_64.AppImage.zsync
zsync|https://example.com/App.AppImage.zsync
```

## How update detection works

Mirrors GearLever’s updaters as closely as practical:

| Source | “Needs update?” heuristic |
|---|---|
| GitHub | Asset `digest` (sha256) if present; else remote size vs local size; for embedded zsync, SHA-1 from the `.zsync` header (or `appimageupdatetool --check-for-update`) |
| Static URL | `Content-Length` vs local size; embedded zsync uses SHA-1 / appimageupdatetool |
| Codeberg / Forgejo | Latest matching asset size vs local size |
| GitLab | HEAD `Content-Length` of the release link vs local size |

Apps with no configured manager and no embedded `.upd_info` are skipped.

## How downloads are staged

**Full downloads (aria2):**

1. Resolve all pending URLs.
2. Download into a temp staging directory (`aria2c` batch input file).
3. Move each file beside the target as `*.turbo-partial`, set executable bit, then `os.replace()` onto the existing GearLever path (atomic on the same filesystem).
4. Desktop files keep pointing at the same path/name GearLever already integrated.

**Delta updates (zsync):**

1. Run `appimageupdatetool --overwrite <AppImage>` in place.
2. If `appimageupdatetool` is missing, fall back to a full aria2 download when a direct URL can be resolved.

## GitHub API rate limits

Unauthenticated GitHub API access is limited. For many AppImages, set a token:

```bash
export GITHUB_TOKEN=ghp_...   # or GH_TOKEN
gearlever-turbo
```

## Design principles

- GearLever stays in charge — only read its data, never fight it
- Single-file, dependency-light — Python 3 stdlib + `aria2c`; optionally `appimageupdatetool`
- Graceful degradation — metadata parsing lives in `parse_gearlever_apps()` so format changes need one place updated
- Scriptable — `--quiet` and meaningful exit codes for cron/systemd

## Assumptions & limitations

- Tested against GearLever **4.x** Flatpak (`it.mijorus.gearlever`) metadata layout. Newer GearLever versions may change `gearlever.conf` / `apps.json`; adjust `parse_gearlever_apps()` if needed.
- `FTPUpdater` sources are not accelerated (skipped with a clear message).
- GearLever’s own “keep old versions” / rename-on-update flows are not reimplemented: turbo always replaces the existing file path (GearLever’s default REPLACE behaviour).
- Desktop entries / icons are not rewritten; path stability is intentional so GearLever keeps working.
- “Up to date” in GearLever is based on size/hash checks against the remote — not a separate status database. Replacing the file with the current release is enough.

## License

MIT — see [LICENSE](LICENSE).
