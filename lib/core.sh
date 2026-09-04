# Shared runtime paths and commands. Loading this file performs no network I/O.
gcr_init() {
    if [ -f "$GCR_INSTALL_ROOT/lib/core.sh" ] && [ -f "$GCR_INSTALL_ROOT/config/defaults.sh" ]; then
        GCR_LIB_DIR="$GCR_INSTALL_ROOT/lib"
        GCR_DEFAULTS_FILE="$GCR_INSTALL_ROOT/config/defaults.sh"
    else
        GCR_LIB_DIR="$GCR_INSTALL_ROOT/.gcr/lib"
        GCR_DEFAULTS_FILE="$GCR_INSTALL_ROOT/.gcr/config/defaults.sh"
    fi
    . "$GCR_DEFAULTS_FILE" || return
    GCR_CONFIG_FILE="${GCR_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/gcr/config.sh}"
    if [ -f "$GCR_CONFIG_FILE" ]; then
        . "$GCR_CONFIG_FILE" || return
    fi
    GCR_RUNTIME_LOADED=1
    GCR_TOOLS_LOADED=0
}

gcr_payload_files() {
    printf '%s\n' \
        lib/core.sh lib/update.sh lib/transaction.sh lib/doctor.sh lib/environment.sh \
        lib/catalog.sh lib/install.sh lib/aicoding.sh \
        lib/installers/cli.sh lib/installers/editors.sh lib/installers/network.sh \
        lib/installers/services.sh \
        config/defaults.sh .ohmyprint .ohmytool .ohmyzsh .p9k.zsh .ohmyshell
}

gcr_target() {
    case "$1" in
        lib/*|config/*) printf '%s/.gcr/%s\n' "$GCR_INSTALL_ROOT" "$1" ;;
        *) printf '%s/%s\n' "$GCR_INSTALL_ROOT" "$1" ;;
    esac
}

gcr_read() {
    GCR_VALUE=""
    [ -f "$1" ] && IFS= read -r GCR_VALUE < "$1"
    return 0
}

gcr_number() {
    case "$1" in ''|*[!0-9]*) return 1 ;; esac
    [ "${#1}" -le 9 ] && [ "$1" -gt 0 ]
}

gcr_fetch() {
    gcr_number "$GCR_CONNECT_TIMEOUT" && gcr_number "$GCR_DOWNLOAD_TIMEOUT" || {
        printf '%s\n' 'GCR network timeouts must be positive integers.' >&2
        return 1
    }
    command curl -fsSL --connect-timeout "$GCR_CONNECT_TIMEOUT" \
        --max-time "$GCR_DOWNLOAD_TIMEOUT" "$@"
}

gcr_sha256() {
    if command -v shasum >/dev/null 2>&1; then
        command shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        command sha256sum "$1" | awk '{print $1}'
    else
        printf '%s\n' 'Install shasum or sha256sum to verify GCR downloads.' >&2
        return 1
    fi
}

gcr_load_tools() {
    [ "${GCR_TOOLS_LOADED:-0}" = 1 ] && return 0
    . "$GCR_INSTALL_ROOT/.ohmytool"
}

gcr() {
    local action="${1:-status}"
    [ "$#" -eq 0 ] || shift
    case "$action" in
        status|doctor)
            . "$GCR_LIB_DIR/doctor.sh" || return
            if [ "$action" = status ]; then gcr_status "$@"; else gcr_doctor "$@"; fi
            ;;
        update|rollback|check)
            . "$GCR_LIB_DIR/update.sh" || return
            case "$action" in
                update) myupdate "$@" ;;
                rollback) gcr_rollback "$@" ;;
                check) gcr_check_update && gcr status ;;
            esac
            ;;
        install|profile)
            . "$GCR_LIB_DIR/install.sh" || return
            if [ "$action" = install ]; then gcr_install "$@"; else gcr_profile "$@"; fi
            ;;
        tools) gcr_load_tools && ohmytool "$@" ;;
        help|-h|--help)
            printf '%s\n' \
                'gcr status                 Show local version and cached update status' \
                'gcr doctor                 Diagnose this installation without changing it' \
                'gcr check                  Refresh cached version metadata now' \
                'gcr update [--no-restart]   Download, verify and install a fixed revision' \
                'gcr rollback               Restore the previous installation' \
                'gcr install NAME [--dry-run] Install a tool or preview its requirements' \
                'gcr profile NAME [--dry-run] Install workstation, server or hpc tools' \
                'gcr tools                  Open the tool menu'
            ;;
        *) printf 'Unknown GCR command: %s\n' "$action" >&2; return 2 ;;
    esac
}

myupdate() { gcr update "$@"; }

# The registry defines the direct commands as well as the menus.
gcr_lazy_tools() {
    local name categories description platforms probe
    while IFS='|' read -r name categories description platforms probe; do
        [ -n "$name" ] || continue
        eval "$name() { gcr_load_tools || return; $name \"\$@\"; }"
    done <<EOF
$GCR_TOOL_CATALOG
EOF
    for name in update_PBShelper update_tssh update_safe_rm update_joshuto; do
        eval "$name() { gcr_load_tools || return; $name \"\$@\"; }"
    done
}

ohmytool() { gcr_load_tools && ohmytool "$@"; }

gcr_check_due() {
    local checked now
    gcr_number "$GCR_UPDATE_INTERVAL" || return 1
    gcr_read "$GCR_STATE_DIR/checked_at"; checked=$GCR_VALUE
    now=$(date +%s) || return
    case "$checked" in
        ''|*[!0-9]*) return 0 ;;
    esac
    if [ "${#checked}" -le 10 ] && [ "$checked" -le "$now" ] &&
        [ $((now - checked)) -lt "$GCR_UPDATE_INTERVAL" ]; then
        return 1
    fi
}

gcr_startup_check() {
    [ "$CHECK_GCR_UPDATE" = true ] || return 0
    case "$-" in *i*) ;; *) return 0 ;; esac
    local revision latest worker
    gcr_read "$GCR_STATE_DIR/revision"; revision=$GCR_VALUE
    gcr_read "$GCR_STATE_DIR/latest"; latest=$GCR_VALUE
    if [ -n "$latest" ] && [ -n "$revision" ] && [ "$latest" != "$revision" ]; then
        ui_note "a GCR update is available; run gcr update"
    fi
    gcr_check_due || return 0
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval '( . "$GCR_LIB_DIR/update.sh" && gcr_check_update --if-due ) </dev/null >/dev/null 2>&1 &!'
    else
        { ( . "$GCR_LIB_DIR/update.sh" && gcr_check_update --if-due ) </dev/null >/dev/null 2>&1 & } 2>/dev/null
        worker=$!
        disown "$worker" 2>/dev/null || true
    fi
}
