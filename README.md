![](doc/cover.png)

## Introduction

[![](https://badgen.net/badge/icon/Website?icon=chrome&label)](https://gcr.junbingao.com) https://gcr.junbingao.com

GCR, make your shell more powerful. Please visit the program homepage for more information.

## Install or upgrade

```sh
curl -fsSL https://gcr.junbingao.com/install.sh | sh
```

Use the same command for a fresh installation or an upgrade from an older GCR.
The installer downloads the source itself; no manual clone is required. Existing
`.zshrc` content and configuration symlinks are preserved. Open a new terminal afterward.

The installer asks which environment you are on (Ubuntu with or without sudo, macOS, NUS HPC, NSCC).
Set `GCR_TARGET` to skip the menu, for example `GCR_TARGET=nscc`.

If the site is unreachable, use the GitHub entry point:

```sh
curl -fsSL https://raw.githubusercontent.com/gaojunbin/GCR/master/install_gcr.sh | sh
```

Installations that predate the modular runtime must run either one-line installer
once because their old `myupdate` cannot install the new modules. Afterward, continue
using `myupdate`. Remote installers deliver published code; unpublished changes in a
local checkout become available only after release.

To install a local checkout instead, run this from its repository directory:

```sh
sh install_gcr.sh
```

## Runtime commands

| Command | Result |
| --- | --- |
| `gcr status` | Show the installed revision and cached update status without a request. |
| `gcr doctor` | Check files, symlinks, PATH, plugins and Conda/Jupyter interpreters. |
| `gcr check` | Refresh upstream revision metadata immediately. |
| `gcr update --no-restart` | Download one commit, verify it, and save a rollback snapshot. |
| `gcr rollback` | Restore the previous installation or recover an interrupted update. |
| `gcr install fzf --dry-run` | Preview a tool's platform and command requirements. |
| `gcr profile workstation --dry-run` | Preview a workstation, server or HPC tool selection. |
| `gcr tools` | Open the interactive tool menu. |

The command hub and direct commands such as `myupdate`, `ohmytool`, `cenv` and
`install_fzf` remain available. Installers load on first use. Interactive shell startup
uses cached metadata and checks in the background at most once per day by default.
Automatic installation is disabled by default.

Keep personal settings in `${XDG_CONFIG_HOME:-$HOME/.config}/gcr/config.sh`:

```sh
CHECK_GCR_UPDATE=false
AUTO_GCR_UPDATE=false
GCR_LOAD_THEME=true
GCR_DOWNLOAD_TIMEOUT=30
```

See [runtime configuration and recovery](doc/runtime.md) for settings, update boundaries,
installation profiles and development checks.

## Development checks

Requirements: Python 3.8+, Bash, Zsh, and `shasum` or `sha256sum`.

```sh
python3 scripts/manifest.py --write  # After changing a managed runtime file.
sh scripts/check.sh
```

The checks validate shell syntax and the release manifest, then run isolated regression
tests with mocked network, Conda and Docker commands. Test installations live in `/tmp`;
the tests do not install tools or change the current user's shell configuration.
GitHub Actions runs the same checks on macOS and Ubuntu.

### Document

[中](doc/manual.md)      [EN](doc/manual-en.md)

### License

This project is released under the Apache 2.0 license.
