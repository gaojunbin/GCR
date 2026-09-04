#!/bin/sh
#
# GCR installer -- make your shell more powerful.
#
#   curl -fsSL https://raw.githubusercontent.com/gaojunbin/GCR/master/install_gcr.sh | sh
#
# Optional environment variables:
#   GCR_TARGET    ubuntu | ubuntu-nosudo | macos | hpc | nscc  -- picks the target, skips the menu
#   GCR_MIRROR_URL  source tarball to install from, empty to always clone from GitHub
#   GCR_NO_ANIM   set to 1 to skip the logo animation
#   NO_COLOR      set to any value to disable colors
#
set -eu

GCR_INSTALL_ROOT="${GCR_INSTALL_ROOT:-$HOME}"
GCR_REPO_URL="${GCR_REPO_URL:-https://github.com/gaojunbin/GCR.git}"
GCR_MIRROR_URL="${GCR_MIRROR_URL-https://gcr.junbingao.com/gcr.tar.gz}"
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

    UI_TRUECOLOR=0
    case "${COLORTERM:-}" in
        truecolor|24bit) UI_TRUECOLOR=1 ;;
    esac

    if [ "$UI_COLOR" = 1 ]; then
        if [ "$UI_TRUECOLOR" = 1 ]; then
            C_ACCENT="${ESC}[38;2;56;189;248m"   # Sky blue
            C_CYAN="${ESC}[38;2;34;211;238m"     # Electric cyan
            C_OK="${ESC}[38;2;52;211;153m"       # Emerald green
            C_WARN="${ESC}[38;2;251;191;36m"     # Warm amber
            C_ERR="${ESC}[38;2;248;113;113m"     # Coral red
            C_PURPLE="${ESC}[38;2;167;139;250m"  # Soft purple
            C_MUTED="${ESC}[38;2;148;163;184m"   # Slate gray
        elif [ "$UI_COLORS256" = 1 ]; then
            C_ACCENT="${ESC}[38;5;39m"
            C_CYAN="${ESC}[38;5;51m"
            C_OK="${ESC}[38;5;42m"
            C_WARN="${ESC}[38;5;214m"
            C_ERR="${ESC}[38;5;203m"
            C_PURPLE="${ESC}[38;5;141m"
            C_MUTED="${ESC}[38;5;245m"
        else
            C_ACCENT="${ESC}[36m"
            C_CYAN="${ESC}[36m"
            C_OK="${ESC}[32m"
            C_WARN="${ESC}[33m"
            C_ERR="${ESC}[31m"
            C_PURPLE="${ESC}[35m"
            C_MUTED="${ESC}[2m"
        fi
        C_RESET="${ESC}[0m"
        C_BOLD="${ESC}[1m"
        C_DIM="${ESC}[2m"
    else
        C_RESET=""
        C_BOLD=""
        C_DIM=""
        C_OK=""
        C_WARN=""
        C_ERR=""
        C_PURPLE=""
        C_CYAN=""
        C_MUTED=""
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
        G_WARN="▲"
        G_DOT="·"
        G_POINT="›"
        G_POINTER="❯"
        G_RADIO_ON="◉"
        G_RADIO_OFF="◯"
        G_ARROW="→"
        G_BLOCK="█"
    else
        G_OK="ok"
        G_ERR="x"
        G_WARN="!"
        G_DOT="-"
        G_POINT=">"
        G_POINTER=">"
        G_RADIO_ON="[*]"
        G_RADIO_OFF="[ ]"
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
    printf '  %s%s%s%s\n' "$C_BOLD" "$C_ACCENT" "$1" "$C_RESET"
}

ui_note() {
    printf '  %s%s%s\n' "$C_MUTED" "$1" "$C_RESET"
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
    printf '  %s%s%s\n' "$C_MUTED" "$1" "$C_RESET"
}

ui_command() {
    printf '    %s%s%s %s%s%s\n' "$C_MUTED" "$" "$C_RESET" "$C_ACCENT" "$1" "$C_RESET"
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
    if [ "$UI_COLOR" = 0 ]; then
        LOGO_C=""
    elif [ "$UI_TRUECOLOR" = 1 ]; then
        case "$1" in
            0|1)   LOGO_C="${ESC}[38;2;56;189;248m" ;;
            2|3)   LOGO_C="${ESC}[38;2;59;130;246m" ;;
            4|5)   LOGO_C="${ESC}[38;2;96;165;250m" ;;
            6|7)   LOGO_C="${ESC}[38;2;129;140;248m" ;;
            8|9)   LOGO_C="${ESC}[38;2;147;197;253m" ;;
            10|11) LOGO_C="${ESC}[38;2;165;180;252m" ;;
            *)     LOGO_C="${ESC}[38;2;199;210;254m" ;;
        esac
    elif [ "$UI_COLORS256" = 1 ]; then
        case "$1" in
            0|1|2|3)   LOGO_C="${ESC}[38;5;39m" ;;
            4|5|6|7|8) LOGO_C="${ESC}[38;5;75m" ;;
            *)         LOGO_C="${ESC}[38;5;111m" ;;
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

# run_step_status <title> <shell command>
# Runs the command behind a spinner and returns its exit status, printing a
# check line on success and nothing on failure, so a caller can try something
# else.
run_step_status() {
    step_title="$1"
    step_cmd="$2"
    step_log="$WORKDIR/step.log"
    : > "$step_log"

    if [ "$UI_TTY" = 0 ] || [ "$UI_FRACSLEEP" = 0 ]; then
        if ( eval "$step_cmd" ) >"$step_log" 2>&1; then
            ui_ok "$step_title"
            return 0
        fi
        return 1
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
        case $((step_i % 4)) in
            0) spin_c="$C_CYAN" ;;
            1) spin_c="$C_ACCENT" ;;
            2) spin_c="$C_PURPLE" ;;
            3) spin_c="$C_OK" ;;
        esac
        printf '\r%s  %s%s%s %s  %s%s%s' "$CLR_LINE" \
            "$spin_c" "$SPIN_CH" "$C_RESET" "$step_title" \
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
        return "$step_status"
    fi
    ui_ok "$step_title"
}

# run_step <title> <shell command>
# Same, but a failure ends the installation with the tail of the log.
run_step() {
    if ! run_step_status "$1" "$2"; then
        step_failed "$1" "$WORKDIR/step.log"
    fi
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
            printf '  %s%s%s %s%s%s %s%s%s %s%-24s%s  %s%s%s\n' \
                "$C_ACCENT" "$G_POINTER" "$C_RESET" \
                "$C_BOLD$C_ACCENT" "$i" "$C_RESET" \
                "$C_ACCENT" "$G_RADIO_ON" "$C_RESET" \
                "$C_BOLD" "$TARGET_LABEL" "$C_RESET" \
                "$C_MUTED" "$TARGET_HINT" "$C_RESET"
        else
            printf '     %s%s%s %s%s%s %s%-24s%s  %s%s%s\n' \
                "$C_MUTED" "$i" "$C_RESET" \
                "$C_MUTED" "$G_RADIO_OFF" "$C_RESET" \
                "$C_RESET" "$TARGET_LABEL" "$C_RESET" \
                "$C_MUTED" "$TARGET_HINT" "$C_RESET"
        fi
        i=$((i + 1))
    done
    ui_gap
    printf '  %s↑/↓ move  ·  1-5 pick  ·  enter confirm  ·  q quit%s\n' \
        "$C_MUTED" "$C_RESET"
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
    printf '  %s%s%s %s%s%s  %s%s%s\n' \
        "$C_OK" "$G_OK" "$C_RESET" \
        "$C_BOLD" "$TARGET_LABEL" "$C_RESET" \
        "$C_MUTED" "(selected)" "$C_RESET"
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
    elif command -v curl >/dev/null 2>&1; then
        ui_ok "curl $(curl --version 2>/dev/null | head -n 1 | awk '{print $2}')"
    elif command -v git >/dev/null 2>&1; then
        ui_ok "git $(git --version 2>/dev/null | awk '{print $3}')"
    else
        die "curl or git is required to download GCR" "install one of them, then run this installer again"
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
    if [ -x "$GCR_INSTALL_ROOT/zsh/bin/zsh" ]; then
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

    if fetch_from_mirror; then
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        die "git is required to download GCR" "install git, or point GCR_MIRROR_URL at a reachable source tarball"
    fi
    run_step "Downloading GCR from GitHub" 'git clone --depth 1 --progress "$GCR_REPO_URL" "$SRC"'
}

# The site mirror is tried first: it is one short URL, it is usually closer, and
# it works on machines that cannot reach github.com. Anything unexpected about
# it falls back to a clone rather than installing something incomplete.
fetch_from_mirror() {
    if [ -z "$GCR_MIRROR_URL" ] || ! command -v curl >/dev/null 2>&1; then
        return 1
    fi

    if ! run_step_status "Downloading GCR" \
        'curl -fsSL --connect-timeout 5 --max-time 120 "$GCR_MIRROR_URL" -o "$WORKDIR/gcr.tar.gz" && tar -xzf "$WORKDIR/gcr.tar.gz" -C "$WORKDIR"'; then
        rm -rf "$SRC"
        ui_note "$GCR_MIRROR_URL is unreachable, falling back to github.com"
        return 1
    fi

    if [ ! -f "$SRC/manifest.sha256" ] || [ ! -f "$SRC/lib/core.sh" ]; then
        rm -rf "$SRC"
        ui_note "the mirror looks incomplete, falling back to github.com"
        return 1
    fi
    return 0
}

copy_oh_my_zsh() (
    # Compile caches belong to the target machine and can be read-only.
    omz_staging="$WORKDIR/oh-my-zsh"
    mkdir -p "$omz_staging" "$GCR_INSTALL_ROOT/.oh-my-zsh" || return
    tar --exclude='*.zwc' --exclude='*.zwc.old' \
        -cf "$WORKDIR/oh-my-zsh.tar" -C "$SRC/oh-my-zsh" . || return
    tar -xf "$WORKDIR/oh-my-zsh.tar" -C "$omz_staging" || return
    cp -R "$omz_staging/." "$GCR_INSTALL_ROOT/.oh-my-zsh/"
)

copy_configs() {
    run_step "Installing Oh My Zsh" 'copy_oh_my_zsh'
    . "$SRC/lib/core.sh"
    . "$SRC/config/defaults.sh"
    . "$SRC/lib/transaction.sh"
    GCR_CONFIG_FILE="${GCR_CONFIG_FILE:-${XDG_CONFIG_HOME:-$GCR_INSTALL_ROOT/.config}/gcr/config.sh}"
    if [ -f "$GCR_CONFIG_FILE" ]; then . "$GCR_CONFIG_FILE"; fi
    installed_revision=$(git -C "$SRC" rev-parse HEAD 2>/dev/null || printf local)
    if [ -n "$(git -C "$SRC" status --porcelain 2>/dev/null)" ]; then installed_revision=local; fi
    if ! gcr_install_payload "$SRC" "$installed_revision"; then
        die "GCR configuration installation failed" "existing files were restored; fix the reported error and retry"
    fi
    ui_ok "installed verified GCR configuration"
}

append_profile() {
    profile_line="$1"
    profile_file="$GCR_INSTALL_ROOT/.bash_profile"
    if [ -L "$profile_file" ] && [ ! -e "$profile_file" ]; then
        die "~/.bash_profile is a broken symlink" "repair its target before installing GCR"
    fi
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

installer_quote() {
    printf '"'
    printf '%s' "$1" | sed 's/[\\"$`]/\\&/g'
    printf '"'
}

hook_bash_profile() {
    zsh_binary=$(installer_quote "$GCR_INSTALL_ROOT/zsh/bin/zsh")
    zsh_directory=$(installer_quote "$GCR_INSTALL_ROOT/zsh/bin")
    append_profile "export PATH=$zsh_directory:\$PATH"
    append_profile "export SHELL=$zsh_binary"
    append_profile "case \$- in *i*) [ -x $zsh_binary ] && exec $zsh_binary -l ;; esac"
}

build_zsh() {
    if [ -x "$GCR_INSTALL_ROOT/zsh/bin/zsh" ]; then
        export PATH="$GCR_INSTALL_ROOT/zsh/bin:$PATH"
        ui_ok "zsh $GCR_ZSH_VERSION already built in ~/zsh"
        return 0
    fi
    mkdir -p "$GCR_INSTALL_ROOT/zsh"
    run_step "Unpacking zsh $GCR_ZSH_VERSION" 'tar -xf "$SRC/zsh/zsh-$GCR_ZSH_VERSION.tar.xz" -C "$GCR_INSTALL_ROOT"'
    run_step "Building zsh $GCR_ZSH_VERSION, this takes a few minutes" '
        cd "$GCR_INSTALL_ROOT/zsh" && ./configure --prefix="$GCR_INSTALL_ROOT/zsh" && make && make install
    '
    export PATH="$GCR_INSTALL_ROOT/zsh/bin:$PATH"
}

installer_root() {
    if [ "$(id -u)" = 0 ]; then "$@"; else sudo "$@"; fi
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
            run_step "Installing zsh" 'installer_root env DEBIAN_FRONTEND=noninteractive apt-get install -y zsh'
            if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
                run_step "Making zsh your login shell" 'installer_root chsh -s "$(command -v zsh)" "$(whoami)"'
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
            hook_bash_profile
            ui_ok "hooked zsh into ~/.bash_profile"
            ;;
        nscc)
            build_zsh
            append_profile 'export FPATH=$HOME/zsh/share/zsh/5.9/functions:$HOME/zsh/share/zsh/site-functions:/usr/local/share/zsh/site-functions:$HOME/.cache/oh-my-zsh/completions:$HOME/.oh-my-zsh/completions:$HOME/.oh-my-zsh/functions:$HOME/.oh-my-zsh/plugins/git:$HOME/.oh-my-zsh/plugins/extract:$HOME/.oh-my-zsh/plugins/autojump:$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting:$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions:$HOME/.oh-my-zsh/custom/plugins/zsh-myincr:$HOME/.oh-my-zsh/plugins/aliases:$HOME/.oh-my-zsh/plugins/docker:$HOME/.oh-my-zsh/plugins/docker-compose:$HOME/.oh-my-zsh/plugins/gitignore:$HOME/.oh-my-zsh/plugins/sudo:$FPATH'
            hook_bash_profile
            ui_ok "hooked zsh into ~/.bash_profile"
            ;;
    esac
}

write_zshrc() {
    zshrc="$GCR_INSTALL_ROOT/.zshrc"
    if [ -L "$zshrc" ] && [ ! -e "$zshrc" ]; then
        die "~/.zshrc is a broken symlink" "repair its target before installing GCR"
    fi
    if ! grep -Fq "$GCR_MARKER" "$zshrc" 2>/dev/null; then
        {
            printf '\n%s\n' "$GCR_MARKER"
            printf 'source %s\n' "$(installer_quote "$GCR_INSTALL_ROOT/.ohmyshell")"
            printf '%s\n' "$GCR_MARKER"
        } >> "$zshrc"
    fi
    if [ -L "$GCR_CONFIG_FILE" ] && [ ! -e "$GCR_CONFIG_FILE" ]; then
        die "GCR_CONFIG_FILE is a broken symlink" "repair its target before installing GCR"
    fi
    if [ ! -e "$GCR_CONFIG_FILE" ]; then
        mkdir -p "${GCR_CONFIG_FILE%/*}"
        cat > "$GCR_CONFIG_FILE" <<'CONFIG_EOF'
# GCR user settings. This file is never replaced by updates.
# CHECK_GCR_UPDATE=true
# AUTO_GCR_UPDATE=false
# SHOW_GCR_INFO=false
# GCR_UPDATE_INTERVAL=86400
# GCR_CONNECT_TIMEOUT=5
# GCR_DOWNLOAD_TIMEOUT=30
# GCR_NO_ANIM=1
CONFIG_EOF
    fi
    if [ "$TARGET" = nscc ] && ! grep -q '^module ()' "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'ZSHRC_EOF'
module () {
    eval "$(/opt/cray/pe/modules/3.2.11.6/bin/modulecmd zsh "$@")"
}
ZSHRC_EOF
    fi
    ui_ok "configured ~/.zshrc; existing content and symlinks were preserved"
    ui_note "user settings: $GCR_CONFIG_FILE"
}

finish() {
    if builds_from_source; then
        restart_command="exec ~/zsh/bin/zsh -l"
    else
        restart_command="exec zsh -l"
    fi

    ui_gap
    printf '  %s╭─%s %s%sGCR is installed and ready!%s\n' "$C_MUTED" "$C_RESET" "$C_BOLD$C_OK" "" "$C_RESET"
    printf '  %s│%s\n' "$C_MUTED" "$C_RESET"
    printf '  %s│%s  To start using GCR, restart your shell or run:\n' "$C_MUTED" "$C_RESET"
    printf '  %s│%s    %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_BOLD$C_ACCENT" "$restart_command" "$C_RESET"
    printf '  %s│%s\n' "$C_MUTED" "$C_RESET"
    printf '  %s│%s  %sQuick start:%s\n' "$C_MUTED" "$C_RESET" "$C_BOLD" "$C_RESET"
    printf '  %s│%s    %s·%s %s%-14s%s %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_ACCENT" "$C_RESET" "$C_BOLD" "ohmyshell" "$C_RESET" "$C_MUTED" "Open GCR interactive command hub" "$C_RESET"
    printf '  %s│%s    %s·%s %s%-14s%s %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_ACCENT" "$C_RESET" "$C_BOLD" "mytool" "$C_RESET" "$C_MUTED" "Daily utilities (jupyter, proxy, disk...)" "$C_RESET"
    printf '  %s│%s    %s·%s %s%-14s%s %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_ACCENT" "$C_RESET" "$C_BOLD" "mygit" "$C_RESET" "$C_MUTED" "Git workflow shortcuts" "$C_RESET"
    printf '  %s│%s\n' "$C_MUTED" "$C_RESET"
    printf '  %s│%s  Docs: %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_ACCENT" "$GCR_SITE" "$C_RESET"
    printf '  %s╰─────────────────────────────────────────────────────────────%s\n' "$C_MUTED" "$C_RESET"
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
    install_zsh
    copy_configs
    write_zshrc
    finish
}

main "$@"
