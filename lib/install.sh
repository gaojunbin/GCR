# Shared installation checks, previews and bounded downloads.
gcr_require() {
    local dependency
    for dependency in "$@"; do
        command -v "$dependency" >/dev/null 2>&1 || {
            ui_err "required command is missing: $dependency"; return 1
        }
    done
}

gcr_tool_record() {
    local requested=$1
    case "$requested" in install_*|new_vps_help) ;; *) requested="install_$requested" ;; esac
    while IFS='|' read -r GCR_TOOL_NAME GCR_TOOL_CATEGORIES GCR_TOOL_DESCRIPTION \
        GCR_TOOL_PLATFORMS GCR_TOOL_PROBE GCR_TOOL_DEPENDENCIES; do
        [ "$GCR_TOOL_NAME" != "$requested" ] || return 0
    done <<EOF
$GCR_TOOL_CATALOG
EOF
    ui_err "unknown tool: $1"
    return 2
}

gcr_tool_installed() {
    local value="${GCR_TOOL_PROBE#*:}"
    case "$GCR_TOOL_PROBE" in
        command:*)
            if [ -n "${ZSH_VERSION:-}" ]; then
                whence -p "$value" >/dev/null 2>&1
            else
                type -P "$value" >/dev/null 2>&1
            fi
            ;;
        file:*) [ -x "$GCR_INSTALL_ROOT/$value" ] ;;
        directory:*) [ -d "$GCR_INSTALL_ROOT/$value" ] ;;
        compose) command docker compose version >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

gcr_install() {
    local name="${1:-}" mode="${2:-}" dependency command_name
    [ -n "$name" ] || { ui_err "usage: gcr install NAME [--dry-run]"; return 2; }
    case "$mode" in ''|--dry-run) ;; *) ui_err "unknown install option: $mode"; return 2 ;; esac
    gcr_tool_record "$name" || return
    command_name=$GCR_TOOL_NAME
    ui_heading "$command_name" "$GCR_TOOL_DESCRIPTION"
    ui_field "Platforms" "$GCR_TOOL_PLATFORMS"
    ui_field "Requires" "${GCR_TOOL_DEPENDENCIES:-no additional commands}"
    if [ "$mode" = --dry-run ]; then
        ui_note "preview only; no commands were executed"
        return 0
    fi
    case ",$GCR_TOOL_PLATFORMS," in
        *",$(uname -s),"*) ;;
        *) ui_err "this installer does not support the current operating system"; return 1 ;;
    esac
    if gcr_tool_installed; then ui_ok "$command_name is already installed"; return 0; fi
    while IFS= read -r dependency; do
        [ -z "$dependency" ] || gcr_require "$dependency" || return
    done <<EOF
$(printf '%s' "$GCR_TOOL_DEPENDENCIES" | tr ',' '\n')
EOF
    gcr_load_tools || return
    "$command_name"
}

gcr_profile() {
    local profile="${1:-}" mode="${2:-}" tools tool failed=0
    case "$mode" in ''|--dry-run) ;; *) ui_err "unknown profile option: $mode"; return 2 ;; esac
    case "$profile" in
        workstation) tools='tssh fzf safe_rm' ;;
        server) tools='docker trzsz safe_rm' ;;
        hpc) tools='trzsz fzf PBShelper' ;;
        *) ui_err "profiles: workstation, server, hpc"; return 2 ;;
    esac
    while IFS= read -r tool; do
        gcr_install "$tool" "$mode" || failed=1
    done <<EOF
$(printf '%s' "$tools" | tr ' ' '\n')
EOF
    [ "$failed" = 0 ]
}

gcr_download_file() (
    local url=$1 output=$2 temporary
    temporary=$(mktemp "${TMPDIR:-/tmp}/gcr-download.XXXXXX") || return
    trap 'command rm -f "$temporary"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    gcr_fetch "$url" -o "$temporary" || return
    if [ -L "$output" ] && [ ! -e "$output" ]; then
        ui_err "broken destination symlink: $output"; return 1
    fi
    command cat "$temporary" > "$output"
)

gcr_run_installer() (
    local url=$1 interpreter=$2 temporary
    shift 2
    temporary=$(mktemp "${TMPDIR:-/tmp}/gcr-installer.XXXXXX") || return
    trap 'command rm -f "$temporary"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    gcr_fetch "$url" -o "$temporary" || return
    command "$interpreter" "$temporary" "$@"
)

# Quote data for a shell assignment without expanding it.
gcr_quote() {
    printf '"'
    printf '%s' "$1" | sed 's/[\\"$`]/\\&/g'
    printf '"'
}

gcr_config_append() {
    if [ -L "$GCR_CONFIG_FILE" ] && [ ! -e "$GCR_CONFIG_FILE" ]; then
        ui_err "broken configuration symlink: $GCR_CONFIG_FILE"; return 1
    fi
    mkdir -p "${GCR_CONFIG_FILE%/*}" || return
    if [ -f "$GCR_CONFIG_FILE" ] && command grep -Fxq "$1" "$GCR_CONFIG_FILE"; then
        return 0
    fi
    printf '\n%s\n' "$1" >> "$GCR_CONFIG_FILE"
}

gcr_save_setting() {
    local name=$1 value=$2 assignment previous
    case "$name" in ''|[0-9]*|*[!a-zA-Z0-9_]*) return 2 ;; esac
    assignment="export $name=$(gcr_quote "$value")"
    if [ -L "$GCR_CONFIG_FILE" ] && [ ! -e "$GCR_CONFIG_FILE" ]; then
        ui_err "broken configuration symlink: $GCR_CONFIG_FILE"; return 1
    fi
    previous=$(command grep -E "^(export )?$name=" "$GCR_CONFIG_FILE" 2>/dev/null | tail -n 1)
    [ "$previous" != "$assignment" ] || return 0
    mkdir -p "${GCR_CONFIG_FILE%/*}" || return
    printf '\n%s\n' "$assignment" >> "$GCR_CONFIG_FILE"
}

gcr_save_path() {
    gcr_config_append "export PATH=$(gcr_quote "$1"):\$PATH"
}

gcr_compose_up() {
    gcr_require docker || return
    command docker compose version >/dev/null 2>&1 || {
        ui_err "Docker Compose plugin is missing; install Docker with Compose"; return 1
    }
    command docker compose config --quiet || return
    command docker compose up -d
}

# A typed directory must exist. The default service directory is created on demand.
gcr_service_location() {
    local parent
    ui_ask "Parent directory" "$GCR_SERVICE_DIR"
    parent=$UI_ANSWER
    if [ "$parent" = "$GCR_SERVICE_DIR" ]; then mkdir -p "$parent" || return; fi
    [ -d "$parent" ] && [ -w "$parent" ] || {
        ui_err "not a writable directory: $parent"; return 1
    }
    GCR_SERVICE_PATH="$parent/$1"
}

gcr_compose_service() (
    local name=$1 url=$2 port="${3:-}"
    gcr_service_location "$name" || return
    if [ -e "$GCR_SERVICE_PATH/docker-compose.yml" ]; then
        cd "$GCR_SERVICE_PATH" || return
        gcr_compose_up || return
        ui_ok "$name started with its existing configuration"
        return 0
    fi
    mkdir -p "$GCR_SERVICE_PATH" || return
    cd "$GCR_SERVICE_PATH" || return
    case "$name" in
        nginx-proxy) mkdir -p data letsencrypt || return ;;
        cloudreve)
            mkdir -p cloudreve/uploads cloudreve/avatar aria2/config data/aria2 || return
            touch cloudreve/conf.ini cloudreve/cloudreve.db || return
            ;;
    esac
    gcr_download_file "$url" docker-compose.yml || return
    gcr_compose_up || return
    ui_ok "$name started"
    [ -z "$port" ] || ui_info "open http://localhost:$port"
)
