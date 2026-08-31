#!/bin/sh
#
# GCR installer -- make your shell more powerful.
#
#   curl -fsSL https://raw.githubusercontent.com/gaojunbin/GCR/master/install_gcr.sh | sh
#
# Optional environment variables:
#   GCR_TARGET    ubuntu | ubuntu-nosudo | macos | hpc | nscc  -- picks the target, skips the menu
#   GCR_NO_ANIM   set to 1 to skip the logo animation
#   NO_COLOR      set to any value to disable colors
#
set -eu

GCR_REPO_URL="${GCR_REPO_URL:-https://github.com/gaojunbin/GCR.git}"
GCR_SITE="https://gcr.junbingao.com"
GCR_ZSH_VERSION="5.9"
GCR_MARKER="# [ Added By GCR ]"

ESC=$(printf '\033')
TARGET="${GCR_TARGET:-}"
SRC=""
WORKDIR=""
PROFILE_MARKED=0

# --------------------------------------------------------------- terminal ---

ui_init() {
    UI_TTY=0
    if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
        UI_TTY=1
    fi

    UI_COLOR=0
    if [ "$UI_TTY" = 1 ] && [ -z "${NO_COLOR:-}" ]; then
        UI_COLOR=1
    fi

    UI_COLORS256=0
    if [ "$UI_COLOR" = 1 ]; then
        case "$(tput colors 2>/dev/null || echo 8)" in
            *[0-9][0-9][0-9]*) UI_COLORS256=1 ;;
        esac
    fi

    if [ "$UI_COLOR" = 1 ]; then
        C_RESET="${ESC}[0m"
        C_BOLD="${ESC}[1m"
        C_DIM="${ESC}[2m"
        C_OK="${ESC}[32m"
        C_WARN="${ESC}[33m"
        C_ERR="${ESC}[31m"
        C_ACCENT="${ESC}[36m"
    else
        C_RESET=""
        C_BOLD=""
        C_DIM=""
        C_OK=""
        C_WARN=""
        C_ERR=""
        C_ACCENT=""
    fi

    if [ "$UI_TTY" = 1 ]; then
        CURSOR_HIDE="${ESC}[?25l"
        CURSOR_SHOW="${ESC}[?25h"
        CLR_LINE="${ESC}[K"
        CLR_BELOW="${ESC}[J"
    else
        CURSOR_HIDE=""
        CURSOR_SHOW=""
        CLR_LINE=""
        CLR_BELOW=""
    fi

    UI_UNICODE=0
    if terminal_supports_unicode; then
        UI_UNICODE=1
    fi

    if [ "$UI_UNICODE" = 1 ]; then
        G_OK="✓"
        G_ERR="✗"
        G_WARN="!"
        G_DOT="·"
        G_POINT="›"
        G_ARROW="→"
        G_BLOCK="█"
    else
        G_OK="ok"
        G_ERR="x"
        G_WARN="!"
        G_DOT="-"
        G_POINT=">"
        G_ARROW="->"
        G_BLOCK="#"
    fi

    UI_COLS=$(tput cols 2>/dev/null || echo 80)
    case "$UI_COLS" in
        ''|*[!0-9]*) UI_COLS=80 ;;
    esac

    UI_FRACSLEEP=0
    if sleep 0.01 2>/dev/null; then
        UI_FRACSLEEP=1
    fi
    UI_TICK=0.08
    if [ "$UI_FRACSLEEP" = 0 ]; then
        UI_TICK=1
    fi
}

terminal_supports_unicode() {
    case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
        *UTF-8*|*utf-8*|*UTF8*|*utf8*) return 0 ;;
    esac
    case "${TERM_PROGRAM:-}" in
        Apple_Terminal|iTerm.app|vscode|WezTerm|ghostty) return 0 ;;
    esac
    return 1
}

tty_available() {
    ( : <>/dev/tty ) 2>/dev/null
}

# ---------------------------------------------------------------- output ---

ui_gap() {
    printf '\n'
}

ui_title() {
    printf '  %s%s%s\n' "$C_BOLD" "$1" "$C_RESET"
}

ui_note() {
    printf '  %s%s%s\n' "$C_DIM" "$1" "$C_RESET"
}

ui_ok() {
    printf '  %s%s%s %s\n' "$C_OK" "$G_OK" "$C_RESET" "$1"
}

ui_warn() {
    printf '  %s%s%s %s\n' "$C_WARN" "$G_WARN" "$C_RESET" "$1"
}

ui_err() {
    printf '  %s%s%s %s\n' "$C_ERR" "$G_ERR" "$C_RESET" "$1"
}

ui_hint() {
    printf '  %s%s%s\n' "$C_DIM" "$1" "$C_RESET"
}

ui_command() {
    printf '    %s%s%s\n' "$C_ACCENT" "$1" "$C_RESET"
}

die() {
    ui_gap
    ui_err "$1"
    if [ -n "${2:-}" ]; then
        ui_note "$2"
    fi
    ui_gap
    exit 1
}

# ------------------------------------------------------------------ logo ---

# GCR drawn on a 14x5 pixel grid, one bit per cell.
logo_row() {
    case "$1" in
        0) LOGO_BITS="01110011101110" ;;
        1) LOGO_BITS="10000100001001" ;;
        2) LOGO_BITS="10110100001110" ;;
        3) LOGO_BITS="10010100001010" ;;
        *) LOGO_BITS="01110011101001" ;;
    esac
}

logo_color() {
    if [ "$UI_COLORS256" = 1 ]; then
        case "$1" in
            0|1|2|3) LOGO_C="${ESC}[38;5;69m" ;;
            4|5|6|7|8) LOGO_C="${ESC}[38;5;75m" ;;
            *) LOGO_C="${ESC}[38;5;81m" ;;
        esac
    elif [ "$UI_COLOR" = 1 ]; then
        LOGO_C="$C_ACCENT"
    else
        LOGO_C=""
    fi
}

logo_highlight() {
    if [ "$UI_COLORS256" = 1 ]; then
        LOGO_H="${ESC}[38;5;195m"
    elif [ "$UI_COLOR" = 1 ]; then
        LOGO_H="${ESC}[1;37m"
    else
        LOGO_H=""
    fi
}

# logo_draw <revealed columns> <highlighted column>
logo_draw() {
    reveal="$1"
    head="$2"
    logo_highlight

    y=0
    while [ "$y" -lt 5 ]; do
        logo_row "$y"
        bits="$LOGO_BITS"
        line="  "
        x=0
        while [ "$x" -lt 14 ]; do
            bit=${bits%"${bits#?}"}
            bits=${bits#?}
            if [ "$x" -lt "$reveal" ] && [ "$bit" = 1 ]; then
                if [ "$x" -eq "$head" ]; then
                    line="${line}${LOGO_H}${G_BLOCK}${G_BLOCK}"
                else
                    logo_color "$x"
                    line="${line}${LOGO_C}${G_BLOCK}${G_BLOCK}"
                fi
            else
                line="${line}  "
            fi
            x=$((x + 1))
        done
        printf '%s%s\n' "$line" "$C_RESET"
        y=$((y + 1))
    done
}

logo_show() {
    ui_gap
    if [ "$UI_TTY" = 0 ] || [ "$UI_FRACSLEEP" = 0 ] || [ "${GCR_NO_ANIM:-}" = 1 ]; then
        logo_draw 14 -1
        ui_gap
        return 0
    fi

    printf '%s' "$CURSOR_HIDE"

    x=1
    while [ "$x" -le 14 ]; do
        logo_draw "$x" $((x - 1))
        sleep 0.025
        printf '%s' "${ESC}[5A"
        x=$((x + 1))
    done

    x=0
    while [ "$x" -lt 14 ]; do
        logo_draw 14 "$x"
        sleep 0.015
        printf '%s' "${ESC}[5A"
        x=$((x + 1))
    done

    logo_draw 14 -1
    printf '%s' "$CURSOR_SHOW"
    ui_gap
}

banner() {
    ui_title "GCR Installer"
    ui_note "Make your shell more powerful"
    ui_gap
}

# ------------------------------------------------------------------ steps ---

spin_char() {
    if [ "$UI_UNICODE" = 1 ]; then
        case $(($1 % 10)) in
            0) SPIN_CH="⠋" ;;
            1) SPIN_CH="⠙" ;;
            2) SPIN_CH="⠹" ;;
            3) SPIN_CH="⠸" ;;
            4) SPIN_CH="⠼" ;;
            5) SPIN_CH="⠴" ;;
            6) SPIN_CH="⠦" ;;
            7) SPIN_CH="⠧" ;;
            8) SPIN_CH="⠇" ;;
            *) SPIN_CH="⠏" ;;
        esac
    else
        case $(($1 % 4)) in
            0) SPIN_CH="-" ;;
            1) SPIN_CH="\\" ;;
            2) SPIN_CH="|" ;;
            *) SPIN_CH="/" ;;
        esac
    fi
}

# Last non-empty line of a log, stripped of carriage returns and escape codes.
log_tail() {
    width=$((UI_COLS - ${#1} - 10))
    if [ "$width" -lt 12 ]; then
        width=12
    fi
    tail -c 2048 "$2" 2>/dev/null \
        | tr '\r' '\n' \
        | sed "s/${ESC}\[[0-9;]*[a-zA-Z]//g" \
        | grep -v '^[[:space:]]*$' \
        | tail -n 1 \
        | cut -c "1-$width"
}

step_failed() {
    printf '%s' "$CURSOR_SHOW"
    ui_err "$1"
    ui_gap
    ui_note "last lines of the failed command:"
    sed "s/${ESC}\[[0-9;]*[a-zA-Z]//g" "$2" | tail -n 12 | while IFS= read -r log_line; do
        printf '    %s%s%s\n' "$C_DIM" "$log_line" "$C_RESET"
    done
    ui_gap
    exit 1
}

# run_step <title> <shell command>
run_step() {
    step_title="$1"
    step_cmd="$2"
    step_log="$WORKDIR/step.log"
    : > "$step_log"

    if [ "$UI_TTY" = 0 ] || [ "$UI_FRACSLEEP" = 0 ]; then
        if ( eval "$step_cmd" ) >"$step_log" 2>&1; then
            ui_ok "$step_title"
            return 0
        fi
        step_failed "$step_title" "$step_log"
    fi

    ( eval "$step_cmd" ) >"$step_log" 2>&1 &
    step_pid=$!

    printf '%s' "$CURSOR_HIDE"
    step_i=0
    step_detail=""
    while kill -0 "$step_pid" 2>/dev/null; do
        if [ $((step_i % 4)) -eq 0 ]; then
            step_detail=$(log_tail "$step_title" "$step_log")
        fi
        spin_char "$step_i"
        printf '\r%s  %s%s%s %s  %s%s%s' "$CLR_LINE" \
            "$C_ACCENT" "$SPIN_CH" "$C_RESET" "$step_title" \
            "$C_DIM" "$step_detail" "$C_RESET"
        step_i=$((step_i + 1))
        sleep "$UI_TICK"
    done

    if wait "$step_pid"; then
        step_status=0
    else
        step_status=$?
    fi
    printf '\r%s%s' "$CLR_LINE" "$CURSOR_SHOW"

    if [ "$step_status" -ne 0 ]; then
        step_failed "$step_title" "$step_log"
    fi
    ui_ok "$step_title"
}

# ------------------------------------------------------------------ input ---

read_key() {
    key_state=$(stty -g < /dev/tty 2>/dev/null || true)
    stty -icanon -echo min 1 time 0 < /dev/tty 2>/dev/null || true
    if ! key=$(dd bs=1 count=1 2>/dev/null < /dev/tty); then
        key=""
    fi
    if [ "$key" = "$ESC" ]; then
        stty min 0 time 1 < /dev/tty 2>/dev/null || true
        key="$key$(dd bs=1 count=2 2>/dev/null < /dev/tty || true)"
    fi
    if [ -n "$key_state" ]; then
        stty "$key_state" < /dev/tty 2>/dev/null || true
    fi
    printf '%s' "$key"
}

ui_confirm() {
    if ! tty_available; then
        return 0
    fi
    printf '  %s?%s %s %s[Y/n]%s ' "$C_WARN" "$C_RESET" "$1" "$C_DIM" "$C_RESET"
    exec 3<>/dev/tty
    if ! IFS= read -r answer <&3; then
        answer=""
    fi
    exec 3>&-
    case "$answer" in
        n|N|no|NO) return 1 ;;
        *) return 0 ;;
    esac
}

target_name() {
    case "$1" in
        1) TARGET_ID="ubuntu";        TARGET_LABEL="Ubuntu / Debian";        TARGET_HINT="installs zsh with apt, needs sudo" ;;
        2) TARGET_ID="ubuntu-nosudo"; TARGET_LABEL="Ubuntu / Debian, no sudo"; TARGET_HINT="builds zsh $GCR_ZSH_VERSION into ~/zsh" ;;
        3) TARGET_ID="macos";         TARGET_LABEL="macOS";                  TARGET_HINT="zsh already ships with the system" ;;
        4) TARGET_ID="hpc";           TARGET_LABEL="NUS HPC / Medicine HPC"; TARGET_HINT="builds zsh $GCR_ZSH_VERSION into ~/zsh" ;;
        *) TARGET_ID="nscc";          TARGET_LABEL="NSCC";                   TARGET_HINT="builds zsh $GCR_ZSH_VERSION, keeps module support" ;;
    esac
}

default_index() {
    case "$(uname -s)" in
        Darwin) printf '3' ;;
        *)
            if command -v sudo >/dev/null 2>&1; then
                printf '1'
            else
                printf '2'
            fi
            ;;
    esac
}

menu_draw() {
    i=1
    while [ "$i" -le 5 ]; do
        target_name "$i"
        if [ "$i" -eq "$1" ]; then
            printf '  %s%s%s %s%-26s%s %s%s%s\n' \
                "$C_ACCENT" "$G_POINT" "$C_RESET" \
                "$C_BOLD" "$TARGET_LABEL" "$C_RESET" \
                "$C_DIM" "$TARGET_HINT" "$C_RESET"
        else
            printf '    %s%-26s%s %s%s%s\n' \
                "$C_DIM" "$TARGET_LABEL" "$C_RESET" \
                "$C_DIM" "$TARGET_HINT" "$C_RESET"
        fi
        i=$((i + 1))
    done
    ui_gap
    ui_hint "up/down move   1-5 pick   enter confirm   q quit"
}

choose_target() {
    if [ -n "$TARGET" ]; then
        case "$TARGET" in
            ubuntu|ubuntu-nosudo|macos|hpc|nscc) return 0 ;;
            *) die "unknown GCR_TARGET: $TARGET" "pick one of: ubuntu, ubuntu-nosudo, macos, hpc, nscc" ;;
        esac
    fi

    selected=$(default_index)

    if [ "$UI_TTY" = 0 ] || ! tty_available; then
        target_name "$selected"
        TARGET="$TARGET_ID"
        ui_note "no terminal detected, using $TARGET_LABEL"
        ui_gap
        return 0
    fi

    ui_title "Where are you installing GCR?"
    ui_gap
    menu_draw "$selected"
    printf '%s' "$CURSOR_HIDE"

    while :; do
        key=$(read_key)
        case "$key" in
            "$ESC[A"|k) selected=$((selected - 1)) ;;
            "$ESC[B"|j) selected=$((selected + 1)) ;;
            1|2|3|4|5)
                selected="$key"
                break
                ;;
            ""|" ")
                break
                ;;
            q|Q|"$ESC")
                printf '%s' "$CURSOR_SHOW"
                ui_gap
                ui_note "installation cancelled"
                ui_gap
                exit 130
                ;;
        esac

        if [ "$selected" -lt 1 ]; then
            selected=5
        fi
        if [ "$selected" -gt 5 ]; then
            selected=1
        fi
        printf '%s' "${ESC}[7A"
        menu_draw "$selected"
    done

    printf '%s%s%s' "${ESC}[7A" "$CLR_BELOW" "$CURSOR_SHOW"
    target_name "$selected"
    TARGET="$TARGET_ID"
    printf '  %s%s%s %s\n' "$C_ACCENT" "$G_ARROW" "$C_RESET" "$TARGET_LABEL"
    ui_gap
}

builds_from_source() {
    case "$TARGET" in
        ubuntu-nosudo|hpc|nscc) return 0 ;;
        *) return 1 ;;
    esac
}

# -------------------------------------------------------------- preflight ---

os_description() {
    case "$(uname -s)" in
        Darwin) printf 'macOS %s (%s)' "$(sw_vers -productVersion 2>/dev/null || echo '')" "$(uname -m)" ;;
        Linux)
            name=$(sed -n 's/^PRETTY_NAME="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/os-release 2>/dev/null | head -n 1)
            printf '%s (%s)' "${name:-Linux}" "$(uname -m)"
            ;;
        *) printf '%s (%s)' "$(uname -s)" "$(uname -m)" ;;
    esac
}

# Use the checkout the script sits in when there is one, otherwise clone.
local_source_dir() {
    case "$0" in
        */*) dir=${0%/*} ;;
        *)
            # Piped into a shell, there is no local checkout to read from.
            if [ ! -f "$0" ]; then
                return 0
            fi
            dir="."
            ;;
    esac
    if [ -f "$dir/.ohmyshell" ] && [ -f "$dir/.ohmyprint" ] && [ -d "$dir/oh-my-zsh" ]; then
        ( cd "$dir" && pwd )
    fi
}

preflight() {
    ui_ok "$(os_description)"

    SRC=$(local_source_dir)
    if [ -n "$SRC" ]; then
        ui_ok "local checkout $SRC"
    elif command -v git >/dev/null 2>&1; then
        ui_ok "git $(git --version 2>/dev/null | awk '{print $3}')"
    else
        die "git is required to download GCR" "install git, then run this installer again"
    fi

    if command -v zsh >/dev/null 2>&1; then
        ui_ok "zsh $(zsh --version 2>/dev/null | awk '{print $2}') already installed"
    else
        ui_note "$G_DOT zsh not installed yet"
    fi
    ui_gap
}

preflight_build_tools() {
    if ! builds_from_source; then
        return 0
    fi
    if [ -x "$HOME/zsh/bin/zsh" ]; then
        return 0
    fi
    if ! command -v make >/dev/null 2>&1; then
        die "make is required to build zsh from source" "load a build toolchain (module load gcc) and try again"
    fi
    if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
        die "a C compiler is required to build zsh from source" "load a build toolchain (module load gcc) and try again"
    fi
}

# ---------------------------------------------------------------- install ---

fetch_source() {
    if [ -n "$SRC" ]; then
        return 0
    fi
    SRC="$WORKDIR/GCR"
    run_step "Downloading GCR" 'git clone --depth 1 --progress "$GCR_REPO_URL" "$SRC"'
}

copy_configs() {
    run_step "Installing shell config" '
        cp "$SRC/.ohmyshell" "$SRC/.ohmytool" "$SRC/.ohmyzsh" "$SRC/.p9k.zsh" "$SRC/.ohmyprint" "$HOME/" &&
        mkdir -p "$HOME/.oh-my-zsh" &&
        cp -R "$SRC/oh-my-zsh/." "$HOME/.oh-my-zsh/"
    '
}

append_profile() {
    profile_line="$1"
    profile_file="$HOME/.bash_profile"
    if [ ! -f "$profile_file" ]; then
        : > "$profile_file"
    fi
    if grep -Fqx "$profile_line" "$profile_file"; then
        return 0
    fi
    if [ "$PROFILE_MARKED" = 0 ]; then
        printf '\n%s\n' "$GCR_MARKER" >> "$profile_file"
        PROFILE_MARKED=1
    fi
    printf '%s\n' "$profile_line" >> "$profile_file"
}

build_zsh() {
    if [ -x "$HOME/zsh/bin/zsh" ]; then
        ui_ok "zsh $GCR_ZSH_VERSION already built in ~/zsh"
        return 0
    fi
    mkdir -p "$HOME/zsh"
    run_step "Unpacking zsh $GCR_ZSH_VERSION" 'tar -xf "$SRC/zsh/zsh-$GCR_ZSH_VERSION.tar.xz" -C "$HOME"'
    run_step "Building zsh $GCR_ZSH_VERSION, this takes a few minutes" '
        cd "$HOME/zsh" && ./configure --prefix="$HOME/zsh" && make && make install
    '
}

install_zsh() {
    case "$TARGET" in
        ubuntu)
            if [ "$(id -u)" != 0 ]; then
                ui_note "zsh is installed with apt, you may be asked for your sudo password"
                if ! sudo -v; then
                    die "sudo authentication failed" "pick the no sudo target to build zsh into ~/zsh instead"
                fi
            fi
            run_step "Installing zsh" 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y zsh'
            if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
                run_step "Making zsh your login shell" 'sudo chsh -s "$(command -v zsh)" "$(whoami)"'
            fi
            ;;
        macos)
            if ! command -v zsh >/dev/null 2>&1; then
                die "zsh was not found on this Mac" "install it with: brew install zsh"
            fi
            ui_ok "using the system zsh"
            case "${SHELL:-}" in
                *zsh) ;;
                *) ui_warn "your login shell is ${SHELL:-unknown}, switch it with: chsh -s $(command -v zsh)" ;;
            esac
            ;;
        ubuntu-nosudo|hpc)
            build_zsh
            append_profile 'export PATH=$HOME/zsh/bin:$PATH'
            append_profile 'export SHELL=$HOME/zsh/bin/zsh'
            append_profile '[ -f $HOME/zsh/bin/zsh ] && exec $HOME/zsh/bin/zsh -l'
            ui_ok "hooked zsh into ~/.bash_profile"
            ;;
        nscc)
            build_zsh
            append_profile 'export FPATH=$HOME/zsh/share/zsh/5.9/functions:$HOME/zsh/share/zsh/site-functions:/usr/local/share/zsh/site-functions:$HOME/.cache/oh-my-zsh/completions:$HOME/.oh-my-zsh/completions:$HOME/.oh-my-zsh/functions:$HOME/.oh-my-zsh/plugins/git:$HOME/.oh-my-zsh/plugins/extract:$HOME/.oh-my-zsh/plugins/autojump:$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting:$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions:$HOME/.oh-my-zsh/custom/plugins/zsh-myincr:$HOME/.oh-my-zsh/plugins/aliases:$HOME/.oh-my-zsh/plugins/docker:$HOME/.oh-my-zsh/plugins/docker-compos:$HOME/.oh-my-zsh/plugins/gitignore:$HOME/.oh-my-zsh/plugins/sud:$FPATH'
            append_profile 'export PATH=$HOME/zsh/bin:$PATH'
            append_profile 'export SHELL=$HOME/zsh/bin/zsh'
            append_profile '[ -f $HOME/zsh/bin/zsh ] && exec $HOME/zsh/bin/zsh -l'
            ui_ok "hooked zsh into ~/.bash_profile"
            ;;
    esac
}

preview_zshrc() {
    sed -n '1,6p' "$1" | while IFS= read -r preview_line; do
        printf '    %s%s%s\n' "$C_DIM" "$preview_line" "$C_RESET"
    done
    if [ "$(wc -l < "$1" | tr -d ' ')" -gt 6 ]; then
        printf '    %s%s%s\n' "$C_DIM" "..." "$C_RESET"
    fi
}

write_zshrc() {
    zshrc="$HOME/.zshrc"

    if [ -s "$zshrc" ]; then
        ui_gap
        ui_warn "~/.zshrc already exists, $(wc -l < "$zshrc" | tr -d ' ') lines"
        preview_zshrc "$zshrc"
        ui_gap
        if ui_confirm "Replace it with a fresh GCR config?"; then
            cp "$zshrc" "$zshrc.gcr-backup"
            : > "$zshrc"
            ui_note "old file kept at ~/.zshrc.gcr-backup"
        else
            ui_note "keeping your file, GCR lines are appended to it"
        fi
        ui_gap
    fi

    if ! grep -Fq "$GCR_MARKER" "$zshrc" 2>/dev/null; then
        {
            printf '%s\n' "$GCR_MARKER"
            printf 'SHOW_GCR_INFO=false\n'
            printf 'CHECK_GCR_UPDATE=true\n'
            printf 'source ~/.ohmyshell\n'
            printf '%s\n' "$GCR_MARKER"
        } >> "$zshrc"
    fi

    if [ "$TARGET" = nscc ] && ! grep -q '^module ()' "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'ZSHRC_EOF'
module ()
{
    eval `/opt/cray/pe/modules/3.2.11.6/bin/modulecmd bash $*`
}
ZSHRC_EOF
    fi

    ui_ok "configured ~/.zshrc"
}

finish() {
    if builds_from_source; then
        restart_command="exec ~/zsh/bin/zsh -l"
    else
        restart_command="exec zsh -l"
    fi

    ui_gap
    ui_title "GCR is installed."
    ui_gap
    ui_note "Restart your shell, or run:"
    ui_gap
    ui_command "$restart_command"
    ui_gap
    ui_note "Docs and updates: $GCR_SITE"
    ui_gap
}

# ------------------------------------------------------------------- main ---

cleanup() {
    printf '%s' "${CURSOR_SHOW:-}"
    if [ -n "${WORKDIR:-}" ] && [ -d "${WORKDIR:-}" ]; then
        rm -rf "$WORKDIR"
    fi
}

on_interrupt() {
    cleanup
    printf '\n'
    ui_note "installation cancelled"
    printf '\n'
    exit 130
}

main() {
    ui_init
    WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/gcr-install.XXXXXX")
    trap cleanup EXIT
    trap on_interrupt INT TERM

    logo_show
    banner
    preflight
    choose_target
    preflight_build_tools
    fetch_source
    copy_configs
    install_zsh
    write_zshrc
    finish
}

main "$@"
