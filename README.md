![](doc/cover.png)

## Introduction

[![](https://badgen.net/badge/icon/Website?icon=chrome&label)](https://gcr.junbingao.com) https://gcr.junbingao.com

GCR, make your shell more powerful. Please visit the program homepage for more information.

## Install

```
curl -fsSL https://gcr.junbingao.com/install.sh | sh
```

The installer asks which environment you are on (Ubuntu with or without sudo, macOS, NUS HPC, NSCC).
Set `GCR_TARGET` to skip the menu, for example `GCR_TARGET=nscc`.

When zsh is already available in `PATH` or at `~/zsh/bin/zsh`, the Linux targets
ask whether to reuse it and skip zsh installation (default: yes). Without a
terminal, the installer reuses it automatically. This skips apt/sudo, source
compilation, build-tool checks, and login-shell/profile changes while still
installing GCR and configuring `~/.zshrc`. After installation, run the displayed
`exec` command to start GCR in zsh. macOS continues to use the system zsh.

Set `GCR_SKIP_ZSH=1` to skip zsh installation without this prompt, or
`GCR_SKIP_ZSH=0` to keep the selected target's normal zsh installation. Skipping
requires an existing zsh; otherwise the installer exits before installing GCR.
For example, from a local checkout:

```sh
GCR_TARGET=ubuntu GCR_SKIP_ZSH=1 sh ./install_gcr.sh
GCR_TARGET=ubuntu-nosudo GCR_SKIP_ZSH=1 sh ./install_gcr.sh
```

If the site is unreachable, install straight from GitHub:

```
curl -fsSL https://raw.githubusercontent.com/gaojunbin/GCR/master/install_gcr.sh | sh
```

### Document

[中](doc/manual.md)      [EN](doc/manual-en.md)

### License

This project is released under the Apache 2.0 license.

