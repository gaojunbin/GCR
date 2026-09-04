# Install and restore file contents in place so configuration symlinks survive.
gcr_verify_payload() {
    local source_dir=$1 file expected actual
    while IFS= read -r file; do
        [ -f "$source_dir/$file" ] && [ ! -L "$source_dir/$file" ] || {
            ui_err "missing release file: $file"; return 1
        }
        expected=$(awk -v file="$file" '$2 == file { print $1 }' "$source_dir/manifest.sha256")
        case "$expected" in ''|*[!0-9a-f]*) ui_err "invalid checksum: $file"; return 1 ;; esac
        [ "${#expected}" -eq 64 ] || return 1
        actual=$(gcr_sha256 "$source_dir/$file") || return
        [ "$actual" = "$expected" ] || { ui_err "checksum mismatch: $file"; return 1; }
        case "$file" in
            .ohmyzsh|.p9k.zsh) command zsh -n "$source_dir/$file" || return ;;
            *)
                command bash -n "$source_dir/$file" || return
                command zsh -n "$source_dir/$file" || return
                ;;
        esac
    done <<EOF
$(gcr_payload_files)
EOF
}

gcr_snapshot() {
    local snapshot=$1 file target
    mkdir -p "$snapshot/files" || return
    : > "$snapshot/present" || return
    gcr_payload_files > "$snapshot/paths" || return
    while IFS= read -r file; do
        target=$(gcr_target "$file")
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            ui_err "broken configuration symlink: $target"; return 1
        fi
        if [ -e "$target" ]; then
            [ -f "$target" ] && [ -r "$target" ] && [ -w "$target" ] || {
                ui_err "configuration is not a writable file: $target"; return 1
            }
            case "$file" in */*) mkdir -p "$snapshot/files/${file%/*}" || return ;; esac
            command cp -p "$target" "$snapshot/files/$file" || return
            printf '%s\n' "$file" >> "$snapshot/present" || return
        fi
    done < "$snapshot/paths"
    if [ -f "$GCR_STATE_DIR/revision" ]; then
        command cp "$GCR_STATE_DIR/revision" "$snapshot/revision" || return
    fi
}

gcr_restore() {
    local snapshot=$1 file target failed=0
    [ -f "$snapshot/paths" ] || return 1
    while IFS= read -r file; do
        target=$(gcr_target "$file")
        if command grep -Fxq "$file" "$snapshot/present"; then
            if command cmp -s "$snapshot/files/$file" "$target"; then continue; fi
            if [ -L "$target" ] && [ ! -e "$target" ]; then
                failed=1
            elif ! command cat "$snapshot/files/$file" > "$target"; then
                failed=1
            fi
        elif [ -e "$target" ] || [ -L "$target" ]; then
            command rm -f "$target" || failed=1
        fi
    done < "$snapshot/paths"
    [ "$failed" = 0 ] || return 1
    if [ -f "$snapshot/revision" ]; then
        command cat "$snapshot/revision" > "$GCR_STATE_DIR/revision" || return
    else
        command rm -f "$GCR_STATE_DIR/revision" || return
    fi
}

gcr_apply_payload() {
    local source_dir=$1 file target
    while IFS= read -r file; do
        target=$(gcr_target "$file")
        mkdir -p "${target%/*}" || return
        if [ -L "$target" ] && [ ! -e "$target" ]; then return 1; fi
        command cat "$source_dir/$file" > "$target" || return
    done <<EOF
$(gcr_payload_files)
EOF
}

gcr_pid_running() {
    local process_state
    kill -0 "$1" 2>/dev/null || return 1
    process_state=$(command ps -p "$1" -o stat= 2>/dev/null)
    case "$process_state" in ''|*Z*) return 1 ;; esac
}

gcr_reap_lock() (
    local lock=$1 owner
    # Serialize stale-lock cleanup; a second caller cannot remove the new lock.
    mkdir "$lock.reap" 2>/dev/null || return 1
    trap 'rmdir "$lock.reap" 2>/dev/null' EXIT
    gcr_read "$lock/pid"; owner=$GCR_VALUE
    case "$owner" in ''|*[!0-9]*) return 1 ;; esac
    gcr_pid_running "$owner" && return 1
    command rm -f "$lock/pid" || return
    rmdir "$lock" 2>/dev/null || return
    mkdir "$lock" 2>/dev/null
)

gcr_lock() {
    local lock=$1
    mkdir "$lock" 2>/dev/null || gcr_reap_lock "$lock" || return 1
    # A fresh sh reports its actual parent even inside a bash/zsh subshell.
    command sh -c 'printf "%s\n" "$PPID"' > "$lock/pid"
}

gcr_unlock() {
    command rm -f "$1/pid"
    rmdir "$1" 2>/dev/null
}

gcr_transaction_cleanup() {
    local code=$1
    trap - EXIT INT TERM
    if [ "$GCR_TRANSACTION_ACTIVE" = 1 ]; then
        if gcr_restore "$GCR_STATE_DIR/pending"; then
            command rm -rf "$GCR_STATE_DIR/pending"
            ui_warn "installation interrupted; previous files restored"
        else
            ui_err "restore incomplete; run gcr rollback after fixing file permissions"
        fi
    fi
    gcr_unlock "$GCR_STATE_DIR/update.lock"
    exit "$code"
}

gcr_install_payload() (
    local source_dir=$1 revision=$2 snapshot
    umask 077
    mkdir -p "$GCR_STATE_DIR" || return
    gcr_verify_payload "$source_dir" || return
    gcr_lock "$GCR_STATE_DIR/update.lock" || { ui_err "another GCR update is running"; return 1; }
    GCR_TRANSACTION_ACTIVE=0
    trap 'gcr_transaction_cleanup $?' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if [ -d "$GCR_STATE_DIR/pending" ]; then
        ui_err "an interrupted update needs recovery; run gcr rollback"; return 1
    fi
    snapshot=$(mktemp -d "$GCR_STATE_DIR/snapshot.XXXXXX") || return
    if ! gcr_snapshot "$snapshot"; then
        command rm -rf "$snapshot"
        return 1
    fi
    command mv "$snapshot" "$GCR_STATE_DIR/pending" || return
    GCR_TRANSACTION_ACTIVE=1
    gcr_apply_payload "$source_dir" || return
    printf '%s\n' "$revision" > "$GCR_STATE_DIR/revision" || return
    command rm -rf "$GCR_STATE_DIR/previous" || return
    command mv "$GCR_STATE_DIR/pending" "$GCR_STATE_DIR/previous" || return
    GCR_TRANSACTION_ACTIVE=0
)

gcr_rollback() (
    local snapshot
    umask 077
    mkdir -p "$GCR_STATE_DIR" || return
    gcr_lock "$GCR_STATE_DIR/download.lock" || { ui_err "another GCR update is running"; return 1; }
    trap 'gcr_unlock "$GCR_STATE_DIR/download.lock"' EXIT
    gcr_lock "$GCR_STATE_DIR/update.lock" || { ui_err "another GCR update is running"; return 1; }
    trap 'gcr_unlock "$GCR_STATE_DIR/update.lock"; gcr_unlock "$GCR_STATE_DIR/download.lock"' EXIT
    snapshot="$GCR_STATE_DIR/previous"
    if [ -d "$GCR_STATE_DIR/pending" ]; then snapshot="$GCR_STATE_DIR/pending"; fi
    if [ ! -f "$snapshot/paths" ]; then
        ui_err "no installation snapshot is available"; return 1
    fi
    if ! gcr_restore "$snapshot"; then
        ui_err "restore incomplete; the snapshot was kept for another attempt"; return 1
    fi
    command rm -rf "$snapshot" || return
    ui_ok "previous configuration restored; restart your shell to load it"
)
