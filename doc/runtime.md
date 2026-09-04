# Runtime, configuration and recovery

## Installation

For a fresh installation or an upgrade, run:

```sh
curl -fsSL https://gcr.junbingao.com/install.sh | sh
```

The installer downloads its source automatically; no manual repository checkout is
needed. The GitHub entry point is available if the site is unreachable:

```sh
curl -fsSL https://raw.githubusercontent.com/gaojunbin/GCR/master/install_gcr.sh | sh
```

Select an environment, then open a new terminal. `GCR_TARGET` can select `ubuntu`,
`ubuntu-nosudo`, `macos`, `hpc` or `nscc` in advance. To set it for the installer:

```sh
curl -fsSL https://gcr.junbingao.com/install.sh | GCR_TARGET=nscc sh
```

Remote entry points install published code. To install unpublished local changes,
run `sh install_gcr.sh` from the checkout instead.

The installer checks or installs Zsh, copies bundled Oh My Zsh, verifies
GCR files and adds the shell entry point. It preserves existing `.zshrc` content and
configuration symlinks. Broken links must be repaired first. Modified checkouts are
recorded as `local` instead of claiming a committed revision.

Oh My Zsh installation skips generated `.zwc` and `.zwc.old` files, including caches
present in a local checkout. Existing device caches and their permissions are kept;
Powerlevel10k can regenerate them from updated source when the shell starts. Release
archives contain source files rather than another machine's compiled caches.

Older installations need to run the one-line installer once: their `myupdate` downloads
only the former top-level files and cannot install the new modules. Subsequent updates
can use the new `myupdate` command. On no-sudo targets,
the Bash login hook starts Zsh only for interactive sessions.

`GCR_INSTALL_ROOT` selects the installation directory, defaulting to the user's home.
For a separate installation, also set `GCR_CONFIG_FILE` to keep its settings separate.
This does not redirect the home directory used by third-party tools.

## Configuration

Personal settings belong in `${XDG_CONFIG_HOME:-$HOME/.config}/gcr/config.sh`, or the
path selected by `GCR_CONFIG_FILE` before loading `.ohmyshell`. This is trusted shell
code loaded after defaults. Existing environment settings remain effective unless
the user settings file overrides them. Updates never replace this file.

| Setting | Default | Meaning |
| --- | --- | --- |
| `CHECK_GCR_UPDATE` | `true` | Enable background version checks in interactive shells. |
| `AUTO_GCR_UPDATE` | `false` | Install an available revision after a successful check. |
| `SHOW_GCR_INFO` | `false` | Show the startup banner and optional tool notices. |
| `GCR_LOAD_THEME` | `true` | Load Oh My Zsh and Powerlevel10k in Zsh; Bash skips them. |
| `GCR_UPDATE_INTERVAL` | `86400` | Seconds between startup checks, including failed attempts. |
| `GCR_CONNECT_TIMEOUT` | `5` | Runtime download connection timeout, in seconds. |
| `GCR_DOWNLOAD_TIMEOUT` | `30` | Maximum time per runtime download, in seconds. |
| `GCR_REPOSITORY` | `gaojunbin/GCR` | GitHub repository for updates. |
| `GCR_UPDATE_REF` | `master` | Branch, tag or commit resolved before downloading. |
| `GCR_API_URL` | `https://api.github.com` | GitHub-compatible API base URL. |
| `GCR_RAW_URL` | `https://raw.githubusercontent.com` | Raw file base URL. |
| `GCR_STATE_DIR` | `$GCR_INSTALL_ROOT/.gcr/state` | Cache, locks and a rollback snapshot. |
| `GCR_SERVICE_DIR` | `$GCR_INSTALL_ROOT/services` | Parent directory for shared Compose installers. |
| `GCR_NO_ANIM` | unset | Set to `1` to disable animations. |

For tools without automatic network checks or a theme:

```sh
CHECK_GCR_UPDATE=false
AUTO_GCR_UPDATE=false
GCR_LOAD_THEME=false
```

Explicit `gcr check` and `gcr update` still make requests. Runtime curl timeouts do
not control package managers, Git or downloads inside third-party installers. The
bootstrap tarball has separate 5-second connection and 120-second total limits.

## Updates and recovery

```sh
gcr status
gcr check
gcr update --no-restart
gcr rollback
```

`status` reads local metadata. Startup reads the cache, displays an available-update
notice and starts a detached check when due. Noninteractive shells do not start
automatic checks. Concurrent checks share a lock. Failed checks keep the previous
upstream revision and record the attempt to throttle subsequent requests.

The updater operates on installed files. In a source checkout, use the installer;
`gcr update` refuses to mix downloaded runtime files with checked-out modules.

An update resolves the requested ref to a full commit ID through GitHub's
[commit API](https://docs.github.com/en/rest/commits/commits#get-a-commit). All payload
files and the SHA-256 manifest come from that commit. Downloads, checksum verification
and shell syntax checks finish before installed content changes. The manifest detects
missing, mixed or corrupted files; it is not a separately signed release.

GCR snapshots the managed files, then writes content in place to preserve existing
symlinks, inodes and permissions. Failed writes and handled interrupts restore the
snapshot. Update and rollback locks prevent concurrent writes. Each successful update
replaces the previous rollback snapshot.

This does not atomically switch the entire installation: another shell can read a
file during the write phase. After an unhandled termination or failed restore, repair
the reported filesystem problem and run `gcr rollback`. Failed recovery retains the
snapshot for another attempt. Restart the shell after updating or rolling back.

If damaged startup files prevent loading GCR, load recovery helpers from an intact
checkout using Bash or Zsh:

```sh
# Run from an intact checkout; adjust the root for a nondefault installation.
GCR_INSTALL_ROOT="$HOME"
. ./lib/core.sh
. ./config/defaults.sh
GCR_CONFIG_FILE="${GCR_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/gcr/config.sh}"
[ ! -f "$GCR_CONFIG_FILE" ] || . "$GCR_CONFIG_FILE"
. ./.ohmyprint
. ./lib/transaction.sh
gcr_rollback
```

Recovery restores file contents; it cannot recreate an external symlink target
deleted independently. Use the original installation's settings and state directory.

The managed payload is defined by `gcr_payload_files` in `lib/core.sh`: the modules,
defaults, `.ohmyshell`, `.ohmytool`, `.ohmyprint`, `.ohmyzsh` and `.p9k.zsh`. Personal
settings, `.zshrc`, `.vimrc`, third-party programs, service data and vendored Oh My Zsh
are outside rollback scope. Bootstrap installation copies Oh My Zsh separately.
Put personal overrides in the user settings file instead of editing managed defaults.

## Tools and environments

`lib/catalog.sh` supplies menus, platform declarations, dependency hints and installed
probes. `gcr install NAME --dry-run` displays metadata without loading or executing
installers. Without `--dry-run`, it checks platform and dependencies, skips a detected
installation and runs the installer. Preview does not resolve package versions or
simulate service and package-manager changes.

| Profile | Tools |
| --- | --- |
| `workstation` | tssh, fzf, safe-rm |
| `server` | Docker with Compose, trzsz, safe-rm |
| `hpc` | trzsz, fzf, PBShelper |

For example, run `gcr profile server --dry-run` to preview, then omit `--dry-run` to
install. Profiles may ask for installation methods and directories. They process all
selected tools and return a nonzero status if any fails. Direct installer commands
remain available and load on first use. GCR-owned settings such as the safe-rm trash
path and rmate port are saved with shell quoting in the user settings file. Vendor
tools may maintain their own configuration.

Service installers use `docker compose`. Shared installers for Nginx Proxy Manager,
Cloudreve, Jellyfin and Lsky-pro validate directories and Compose configuration before
starting. They reuse existing Compose files. Deployment failures return nonzero.
Other service-specific prompts remain interactive. Docker installation follows the
official [APT instructions](https://docs.docker.com/engine/install/ubuntu/); optional
GPU setup follows the [NVIDIA Container Toolkit guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

Conda menus use `conda env list --json` and select actual prefixes, so spaces and
duplicate directory names do not select another environment. Fresh environments
include ipykernel; registration runs through that environment's Python. `gcr doctor`
checks missing interpreters and uniquely matched environment/kernel names, along with
files, symlinks, PATH entries and plugins. It reports issues without changing them.

## Development checks

```sh
python3 scripts/manifest.py --write
sh scripts/check.sh
```

Regenerate the manifest after managed-file changes. Checks validate the bootstrap
with `sh -n`, runtime files with Bash and Zsh, and themes with Zsh. Tests require
Python 3.8+, Bash, Zsh and `shasum` or `sha256sum`. Real pseudo-terminals exercise
CSI/SS3 arrows, search, multi-select, cancellation and terminal restoration.

Tests create installations in `/tmp` and substitute network, Conda and Docker commands.
They cover failed downloads, checksum mismatches, interrupted writes, rollback,
symlinks, cache throttling, lazy loading, quoted settings, installer and service errors,
and environment selection. They do not build third-party tools or deploy services.
GitHub Actions runs the suite on macOS and Ubuntu. HPC hosts require validation in
their actual environment.
