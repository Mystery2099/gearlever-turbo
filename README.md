# gearlever-turbo

Parallel update accelerator companion for [GearLever](https://github.com/mijorus/gearlever) (AppImage manager), powered by [aria2](https://aria2.github.io/).

**This is not a fork or replacement for GearLever.** GearLever stays in charge of integration, desktop files, icons, and configuration. `gearlever-turbo` only does one job: discover every managed AppImage from GearLever’s own data, check for updates concurrently, and download them fast.

> **Note:** This project was written by AI.

## Quick start

```bash
# 1. Dependencies (Debian/Ubuntu; needs Git + Python 3.10+ as python3)
sudo apt install aria2 binutils git python3

# 2. Install to ~/.local/bin
git clone https://github.com/Mystery2099/gearlever-turbo.git
cd gearlever-turbo
./setup.sh install
# (alias: ./install.sh)

# Ensure ~/.local/bin is on PATH (current shell + shell config if needed)
export PATH="$HOME/.local/bin:$PATH"

# 3. Check for updates (no downloads)
gearlever-turbo --check
# Or: ~/.local/bin/gearlever-turbo --check

# 4. Update AppImages (prompts for confirmation on a terminal)
gearlever-turbo

# Later: update gearlever-turbo itself
gearlever-turbo --self-update
```

On an interactive terminal, the default run shows a compact update list and plan, then asks before downloading. OK/SKIP rows are collapsed into counts (use `-v` to expand). Aria2 progress is shown without redirect spam. Use `--yes` to skip the prompt, `--quiet` for cron/systemd, or `--topgrade` for a one-line Topgrade-friendly summary.

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
git clone https://github.com/Mystery2099/gearlever-turbo.git
cd gearlever-turbo
./setup.sh install
# installs to ~/.local/bin/gearlever-turbo (no sudo)
# alias: ./install.sh
```

Or manually:

```bash
chmod +x gearlever-turbo
mkdir -p ~/.local/bin
cp gearlever-turbo ~/.local/bin/
```

Clone helpers live in one script:

```bash
./setup.sh install     # copy to ~/.local/bin
./setup.sh update      # git pull --ff-only + reinstall
./setup.sh uninstall   # remove ~/.local/bin/gearlever-turbo
./setup.sh             # usage
```

`./install.sh`, `./update.sh`, and `./uninstall.sh` are thin wrappers around those commands.

### Updating gearlever-turbo

```bash
# Recommended: update the installed binary from GitHub
gearlever-turbo --self-update

# If you keep a git clone:
cd gearlever-turbo
./setup.sh update   # git pull --ff-only + reinstall to ~/.local/bin
# alias: ./update.sh
```

You can also add `gearlever-turbo --self-update` as a separate Topgrade custom command if you want Topgrade to refresh the tool itself.

### Uninstalling gearlever-turbo

```bash
# Recommended: remove the installed binary
gearlever-turbo --self-uninstall
# skip the confirm prompt:
gearlever-turbo --self-uninstall --yes

# Or from a clone:
./setup.sh uninstall
# alias: ./uninstall.sh
```

This only removes `~/.local/bin/gearlever-turbo`. It does **not** remove GearLever, AppImages, or a git clone of this repo.

## Usage

```bash
gearlever-turbo              # Check, confirm, then update (pretty TTY UI)
gearlever-turbo -v           # Show every OK / SKIP row
gearlever-turbo --check      # Show what would update (alias: --dry-run)
gearlever-turbo --yes        # Update without confirmation prompt
gearlever-turbo --topgrade   # Quiet + one summary line (Topgrade / automation)
gearlever-turbo --self-update # Update this script from the latest GitHub release
gearlever-turbo --self-uninstall # Remove ~/.local/bin/gearlever-turbo
gearlever-turbo --quiet      # Quiet mode for cron / systemd timers
gearlever-turbo --jobs 8 --connections 16
gearlever-turbo --help
```

| Flag | Description |
|---|---|
| `--check` / `--dry-run` | Resolve and list updates; download nothing |
| `--yes` / `-y` | Download without asking for confirmation |
| `--verbose` / `-v` | Show every OK / SKIP row and extra plan detail |
| `--quiet` / `-q` | Suppress progress; errors still go to stderr (also skips confirm) |
| `--topgrade` | Implies `--quiet` + `--yes`; prints one summary line to stdout |
| `--self-update` | Fetch latest *released* script from GitHub and replace this binary |
| `--self-uninstall` | Remove `~/.local/bin/gearlever-turbo` (confirm on TTY unless `--yes`) |
| `--jobs` / `-j` | Parallel resolve workers and concurrent aria2 downloads (default: 4) |
| `--connections` / `-x` | aria2 connections per server (default: 16) |
| `--config-dir DIR` | Override GearLever config directory |

**Confirmation:** On a TTY, interactive runs prompt `Do you want to continue?` after the plan. Non-TTY, `--yes`, `--quiet`, and `--topgrade` skip the prompt and proceed.

**Colors:** Status labels and section headers use ANSI colors on a TTY. Set `NO_COLOR=1` to disable.

### Topgrade

In Topgrade’s custom commands / config, prefer:

```toml
gearlever-turbo --topgrade
```

Example summary lines: `Nothing to update.` / `Updated: T3 Code (Nightly).` / `Updated: A. Failed: B (reason).`

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Success (including “nothing to do” or user aborted confirm) |
| `1` | Partial failure (some apps failed to resolve or install) |
| `2` | Setup problem (missing GearLever data, missing `aria2c`, bad flags) |

### Scheduled updates

**cron** (user crontab):

```cron
# Every day at 04:30
30 4 * * * /home/YOU/.local/bin/gearlever-turbo --topgrade
```

**systemd user timer** — `~/.config/systemd/user/gearlever-turbo.service`:

```ini
[Unit]
Description=Parallel GearLever AppImage updates

[Service]
Type=oneshot
ExecStart=%h/.local/bin/gearlever-turbo --topgrade
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

Apps with no configured manager and no embedded `.upd_info` are skipped (with a hint to set an Update URL in GearLever).

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
- Scriptable — `--topgrade` / `--quiet` / `--yes` and meaningful exit codes for cron/systemd/Topgrade

## Assumptions & limitations

- Tested against GearLever **4.x** Flatpak (`it.mijorus.gearlever`) metadata layout. Newer GearLever versions may change `gearlever.conf` / `apps.json`; adjust `parse_gearlever_apps()` if needed.
- `FTPUpdater` sources are not accelerated (skipped with a clear message).
- GearLever’s own “keep old versions” / rename-on-update flows are not reimplemented: turbo always replaces the existing file path (GearLever’s default REPLACE behaviour).
- Desktop entries / icons are not rewritten; path stability is intentional so GearLever keeps working.
- “Up to date” in GearLever is based on size/hash checks against the remote — not a separate status database. Replacing the file with the current release is enough.

## Support (totally optional)

This project is free, and it always will be. Nobody owes me anything for it.

If you somehow still want to tip, you can [buy me a coffee](https://buymeacoffee.com/mystery2099). No pressure at all.

## License

MIT — see [LICENSE](LICENSE).
