# AI tool metadata, version checks and installation.

aicoding_info() {
    case "$1" in
        claude)
            AICODING_NAME="Claude Code"
            AICODING_CMD="claude"
            AICODING_URL="https://code.claude.com/docs/en/setup"
            AICODING_INSTALL_URL="https://claude.ai/install.sh"
            AICODING_INSTALL_SHELL=bash
            AICODING_UPDATE_ARGS="update"
            ;;
        codex)
            AICODING_NAME="Codex"
            AICODING_CMD="codex"
            AICODING_URL="https://github.com/openai/codex"
            AICODING_INSTALL_URL="https://chatgpt.com/codex/install.sh"
            AICODING_INSTALL_SHELL=sh
            AICODING_UPDATE_ARGS="update"
            ;;
        cursor)
            # cursor-agent, not agent: the Grok Build installer links an agent too.
            AICODING_NAME="Cursor CLI"
            AICODING_CMD="cursor-agent"
            AICODING_URL="https://cursor.com/docs/cli/installation"
            AICODING_INSTALL_URL="https://cursor.com/install"
            AICODING_INSTALL_SHELL=bash
            AICODING_UPDATE_ARGS="update"
            ;;
        grok)
            AICODING_NAME="Grok Build"
            AICODING_CMD="grok"
            AICODING_URL="https://docs.x.ai/build/overview"
            AICODING_INSTALL_URL="https://x.ai/cli/install.sh"
            AICODING_INSTALL_SHELL=bash
            AICODING_UPDATE_ARGS="update"
            ;;
        antigravity)
            AICODING_NAME="Antigravity CLI"
            AICODING_CMD="agy"
            AICODING_URL="https://antigravity.google/docs/cli/install/"
            AICODING_INSTALL_URL="https://antigravity.google/cli/install.sh"
            AICODING_INSTALL_SHELL=bash
            AICODING_UPDATE_ARGS="update"
            ;;
        *)
            ui_err "unknown AI coding tool: $1"
            return 1
            ;;
    esac
}

aicoding_which() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        AICODING_BIN=$(whence -p "$1" 2>/dev/null)
    else
        AICODING_BIN=$(type -P "$1" 2>/dev/null)
    fi
    [ -n "$AICODING_BIN" ]
}

aicoding_bin() {
    local dir
    aicoding_info "$1" || return 1
    if aicoding_which "$AICODING_CMD"; then
        return 0
    fi
    for dir in "$HOME/.local/bin" "$HOME/.grok/bin"; do
        if [ -x "$dir/$AICODING_CMD" ]; then
            AICODING_BIN="$dir/$AICODING_CMD"
            return 0
        fi
    done
    AICODING_BIN=""
    return 1
}

aicoding_fetch() {
    gcr_fetch "$1"
}

aicoding_normalize_version() {
    printf '%s\n' "$1" | sed -n \
        's/^[^0-9]*\([0-9][0-9A-Za-z._+-]*\).*$/\1/p' | head -n 1
}

aicoding_current_version() {
    local output
    AICODING_CURRENT=""
    aicoding_bin "$1" || return 1
    output=$("$AICODING_BIN" --version </dev/null 2>&1 || true)
    AICODING_CURRENT=$(aicoding_normalize_version "$output")
    [ -n "$AICODING_CURRENT" ]
}

aicoding_latest_version() {
    local payload latest os arch platform installer release_base channel
    AICODING_LATEST=""

    case "$1" in
        claude)
            channel=$(sed -n \
                's/.*"autoUpdatesChannel"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                "$HOME/.claude/settings.json" 2>/dev/null | head -n 1 || true)
            case "$channel" in
                stable|latest) ;;
                *) channel="latest" ;;
            esac
            latest=$(aicoding_fetch \
                "https://downloads.claude.ai/claude-code-releases/${channel}" 2>/dev/null || true)
            ;;
        codex)
            payload=$(aicoding_fetch \
                "https://releases.openai.com/codex/channels/latest" 2>/dev/null || true)
            latest=$(printf '%s\n' "$payload" | sed -n \
                's/.*"tag_name"[[:space:]]*:[[:space:]]*"rust-v\([^"]*\)".*/\1/p' | head -n 1)
            if [ -z "$latest" ]; then
                payload=$(aicoding_fetch \
                    "https://api.github.com/repos/openai/codex/releases/latest" 2>/dev/null || true)
                latest=$(printf '%s\n' "$payload" | sed -n \
                    's/.*"tag_name"[[:space:]]*:[[:space:]]*"rust-v\([^"]*\)".*/\1/p' | head -n 1)
            fi
            ;;
        cursor)
            payload=$(aicoding_fetch "https://cursor.com/install" 2>/dev/null || true)
            latest=$(printf '%s\n' "$payload" | sed -n \
                's|.*downloads\.cursor\.com/[^/]*/\([^/"]*\)/.*|\1|p' | head -n 1)
            ;;
        grok)
            # Grok exposes a non-mutating, channel-aware machine-readable check.
            if aicoding_bin grok >/dev/null 2>&1; then
                payload=$("$AICODING_BIN" update --check --json </dev/null 2>/dev/null || true)
                latest=$(printf '%s\n' "$payload" | sed -n \
                    's/.*"latestVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
            fi
            # Older Grok builds did not have --check; use their configured
            # channel pointer, with stable as the default.
            if [ -z "$latest" ]; then
                channel=$(sed -n \
                    's/^[[:space:]]*channel[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
                    "$HOME/.grok/config.toml" 2>/dev/null | head -n 1 || true)
                case "$channel" in
                    stable|alpha|enterprise) ;;
                    *) channel="stable" ;;
                esac
                latest=$(aicoding_fetch "https://x.ai/cli/${channel}" 2>/dev/null || true)
                if [ -z "$latest" ]; then
                    latest=$(aicoding_fetch \
                        "https://storage.googleapis.com/grok-build-public-artifacts/cli/${channel}" \
                        2>/dev/null || true)
                fi
            fi
            ;;
        antigravity)
            case "$(uname -s)" in
                Darwin) os="darwin" ;;
                Linux) os="linux" ;;
                *) return 1 ;;
            esac
            case "$(uname -m)" in
                x86_64|amd64) arch="amd64" ;;
                arm64|aarch64) arch="arm64" ;;
                *) return 1 ;;
            esac
            if [ "$os" = "linux" ] && \
                { [ -f /lib/libc.musl-x86_64.so.1 ] || \
                  [ -f /lib/libc.musl-aarch64.so.1 ] || \
                  { command -v ldd >/dev/null 2>&1 && ldd /bin/ls 2>&1 | grep -q musl; }; }; then
                platform="linux_${arch}_musl"
            else
                platform="${os}_${arch}"
            fi
            installer=$(aicoding_fetch "https://antigravity.google/cli/install.sh" 2>/dev/null || true)
            release_base=$(printf '%s\n' "$installer" | sed -n \
                's/^DOWNLOAD_BASE_URL="\([^"]*\)".*/\1/p' | head -n 1)
            release_base=${release_base:-https://antigravity-cli-auto-updater-974169037036.us-central1.run.app}
            payload=$(aicoding_fetch \
                "${release_base}/manifests/${platform}.json" \
                2>/dev/null || true)
            latest=$(printf '%s\n' "$payload" | sed -n \
                's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
            ;;
        *)
            return 1
            ;;
    esac

    AICODING_LATEST=$(aicoding_normalize_version "$latest")
    [ -n "$AICODING_LATEST" ]
}

aicoding_version_is_newer() {
    local candidate installed candidate_base installed_base
    candidate=${1#v}
    candidate=${candidate#rust-v}
    installed=${2#v}
    installed=${installed#rust-v}
    candidate_base=${candidate%%-*}
    installed_base=${installed%%-*}

    awk -v candidate="$candidate" -v installed="$installed" \
        -v candidate_base="$candidate_base" -v installed_base="$installed_base" '
        BEGIN {
            candidate_count = split(candidate_base, candidate_part, ".")
            installed_count = split(installed_base, installed_part, ".")
            count = candidate_count > installed_count ? candidate_count : installed_count
            for (i = 1; i <= count; i++) {
                candidate_number = candidate_part[i] + 0
                installed_number = installed_part[i] + 0
                if (candidate_number > installed_number) exit 0
                if (candidate_number < installed_number) exit 1
            }
            if (candidate == installed) exit 1

            candidate_prerelease = index(candidate, "-") > 0
            installed_prerelease = index(installed, "-") > 0
            if (!candidate_prerelease && installed_prerelease) exit 0
            if (candidate_prerelease && !installed_prerelease) exit 1

            # Cursor versions use YYYY.MM.DD plus an opaque build hash. There is
            # no meaningful ordering between hashes on the same date.
            if (candidate_count == 3 && length(candidate_part[1]) == 4 &&
                candidate_part[1] + 0 >= 2000) exit 0

            candidate_suffix = substr(candidate, index(candidate, "-") + 1)
            installed_suffix = substr(installed, index(installed, "-") + 1)
            candidate_suffix_count = split(candidate_suffix, candidate_suffix_part, ".")
            installed_suffix_count = split(installed_suffix, installed_suffix_part, ".")
            suffix_count = candidate_suffix_count > installed_suffix_count ? candidate_suffix_count : installed_suffix_count
            for (i = 1; i <= suffix_count; i++) {
                candidate_id = candidate_suffix_part[i]
                installed_id = installed_suffix_part[i]
                if (candidate_id == installed_id) continue
                if (candidate_id == "") exit 1
                if (installed_id == "") exit 0

                candidate_numeric = candidate_id ~ /^[0-9]+$/
                installed_numeric = installed_id ~ /^[0-9]+$/
                if (candidate_numeric && installed_numeric) {
                    if (candidate_id + 0 > installed_id + 0) exit 0
                    exit 1
                }
                # Semver numeric identifiers have lower precedence than text.
                if (candidate_numeric && !installed_numeric) exit 1
                if (!candidate_numeric && installed_numeric) exit 0
                if ("_" candidate_id > "_" installed_id) exit 0
                exit 1
            }
            exit 1
        }
    '
}

aicoding_status() {
    AICODING_STATE="missing"
    AICODING_CURRENT=""
    AICODING_LATEST=""
    aicoding_info "$1" || return 1
    if ! aicoding_bin "$1"; then
        return 0
    fi
    AICODING_STATE="unknown"
    if ! aicoding_current_version "$1"; then
        return 0
    fi
    if ! aicoding_latest_version "$1"; then
        return 0
    fi
    if [ "$AICODING_CURRENT" = "$AICODING_LATEST" ]; then
        AICODING_STATE="current"
    elif aicoding_version_is_newer "$AICODING_LATEST" "$AICODING_CURRENT"; then
        AICODING_STATE="update"
    else
        AICODING_STATE="ahead"
    fi
}

aicoding_row() {
    case "$AICODING_STATE" in
        missing)
            printf '  %s%2s%s  %-18s %s  %snot installed%s\n' \
                "$UI_MUTED" "$1" "$UI_RESET" "$AICODING_NAME" \
                "$(ui_badge err "MISSING")" \
                "$UI_MUTED" "$UI_RESET"
            ;;
        update)
            printf '  %s%2s%s  %-18s %s  %s%s %s %s%s\n' \
                "$UI_MUTED" "$1" "$UI_RESET" "$AICODING_NAME" \
                "$(ui_badge warn "UPDATE")" \
                "$UI_MUTED" "$AICODING_CURRENT" "$UI_G_ARROW" "$AICODING_LATEST" "$UI_RESET"
            ;;
        current)
            printf '  %s%2s%s  %-18s %s  %s%s (latest)%s\n' \
                "$UI_MUTED" "$1" "$UI_RESET" "$AICODING_NAME" \
                "$(ui_badge ok "READY")" \
                "$UI_MUTED" "$AICODING_CURRENT" "$UI_RESET"
            ;;
        ahead)
            printf '  %s%2s%s  %-18s %s  %s%s (ahead of %s)%s\n' \
                "$UI_MUTED" "$1" "$UI_RESET" "$AICODING_NAME" \
                "$(ui_badge purple "DEV")" \
                "$UI_MUTED" "$AICODING_CURRENT" "$AICODING_LATEST" "$UI_RESET"
            ;;
        *)
            printf '  %s%2s%s  %-18s %s  %s%s%s\n' \
                "$UI_MUTED" "$1" "$UI_RESET" "$AICODING_NAME" \
                "$(ui_badge info "INSTALLED")" \
                "$UI_MUTED" "${AICODING_CURRENT:-installed}" "$UI_RESET"
            ;;
    esac
}

aicoding_install() {
    local dir
    aicoding_info "$1" || return 1
    ui_heading "install ${AICODING_NAME}" "$AICODING_URL"
    ui_note "download $AICODING_INSTALL_URL and run with $AICODING_INSTALL_SHELL"
    ui_gap
    gcr_run_installer "$AICODING_INSTALL_URL" "$AICODING_INSTALL_SHELL" || return
    ui_gap
    if ! aicoding_bin "$1"; then
        ui_err "${AICODING_NAME} did not install, see ${AICODING_URL}"
        ui_gap
        return 1
    fi
    ui_ok "${AICODING_NAME} installed at ${AICODING_BIN}"
    dir=${AICODING_BIN%/*}
    case ":$PATH:" in
        *":$dir:"*) ;;
        *)
            export PATH="$dir:$PATH"
            ui_note "${dir} added to PATH for this session"
            ;;
    esac
    ui_gap
}

aicoding_update() {
    local before expected after update_bin update_help
    aicoding_info "$1" || return 1
    if ! aicoding_bin "$1"; then
        ui_err "${AICODING_NAME} is not installed"
        return 1
    fi
    update_bin="$AICODING_BIN"
    aicoding_current_version "$1" || true
    before="$AICODING_CURRENT"
    update_help=$("$update_bin" --help </dev/null 2>&1 || true)
    if ! printf '%s\n' "$update_help" | \
        command grep -E '^[[:space:]]*update([^[:alnum:]_]|$)' >/dev/null; then
        ui_err "${AICODING_NAME} ${before:+${before} }does not expose a safe update command"
        ui_note "update it from ${AICODING_URL}"
        ui_gap
        return 1
    fi
    aicoding_latest_version "$1" || true
    expected="$AICODING_LATEST"

    ui_heading "update ${AICODING_NAME}" "$AICODING_URL"
    ui_command "${update_bin} ${AICODING_UPDATE_ARGS}"
    ui_gap
    if ! "$update_bin" "$AICODING_UPDATE_ARGS"; then
        ui_gap
        ui_err "${AICODING_NAME} update failed, see ${AICODING_URL}"
        ui_gap
        return 1
    fi
    ui_gap

    if ! aicoding_current_version "$1"; then
        ui_warn "update finished, but ${AICODING_NAME} version could not be verified"
        ui_gap
        return 0
    fi
    after="$AICODING_CURRENT"
    if [ -n "$before" ] && [ "$after" != "$before" ]; then
        ui_ok "${AICODING_NAME} updated: ${before} ${UI_G_ARROW} ${after}"
    elif [ -n "$expected" ] && [ "$after" = "$expected" ]; then
        ui_ok "${AICODING_NAME} is up to date (${after})"
    elif [ -n "$expected" ] && aicoding_version_is_newer "$expected" "$after"; then
        ui_warn "updater finished, but the active binary still reports ${after} (latest ${expected})"
        ui_note "check PATH precedence: ${AICODING_BIN}"
    else
        ui_ok "${AICODING_NAME} update finished (${after})"
    fi
    ui_gap
}

install_aicoding() {
    local tool i=0 unknown_count=0 completed=0 failed=0 tools items action
    ui_heading "install_aicoding" "AI coding agents"

    # tools holds action:tool pairs in the order of the choose list.
    tools=()
    items=()
    for tool in claude codex cursor grok antigravity; do
        i=$((i + 1))
        aicoding_info "$tool" || continue
        ui_spin_start "Checking ${AICODING_NAME}"
        aicoding_status "$tool"
        ui_spin_stop clear
        aicoding_row "$i"
        case "$AICODING_STATE" in
            missing)
                tools+=("install:$tool")
                items+=("${AICODING_NAME}|install")
                ;;
            update)
                tools+=("update:$tool")
                items+=("${AICODING_NAME}|update ${AICODING_CURRENT} ${UI_G_ARROW} ${AICODING_LATEST}")
                ;;
            unknown)
                unknown_count=$((unknown_count + 1))
                ;;
        esac
    done
    ui_gap

    if [ "${#tools[@]}" -eq 0 ]; then
        if [ "$unknown_count" = 0 ]; then
            ui_ok "everything is installed and up to date"
        else
            ui_warn "everything is installed; ${unknown_count} update check(s) could not be completed"
        fi
        ui_note "launchers: cc, cx, cursor, google, grok"
        ui_gap
        return 0
    fi

    ui_choose "Install / update" "pick what to run" "${items[@]}" || return 1
    if [ "$UI_PICK_COUNT" -eq 0 ]; then
        return 0
    fi

    i=0
    for action in "${tools[@]}"; do
        i=$((i + 1))
        ui_picked "$i" || continue
        tool=${action#*:}
        case "${action%%:*}" in
            install)
                if aicoding_install "$tool"; then
                    completed=$((completed + 1))
                else
                    failed=$((failed + 1))
                fi
                ;;
            *)
                if aicoding_update "$tool"; then
                    completed=$((completed + 1))
                else
                    failed=$((failed + 1))
                fi
                ;;
        esac
    done

    if [ "$completed" -gt 0 ]; then
        ui_note "launchers: cc, cx, cursor, google, grok work now, the plain commands after a new shell"
    fi
    if [ "$failed" -gt 0 ]; then
        ui_warn "${failed} install/update operation(s) failed"
    fi
    ui_gap
    [ "$failed" -eq 0 ]
}
