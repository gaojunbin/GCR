. "$GCR_LIB_DIR/transaction.sh"

gcr_revision_valid() {
    case "$1" in ''|*[!0-9a-f]*) return 1 ;; esac
    [ "${#1}" -eq 40 ]
}

gcr_latest_revision() {
    local revision
    revision=$(gcr_fetch -H 'Accept: application/vnd.github.sha' \
        "$GCR_API_URL/repos/$GCR_REPOSITORY/commits/$GCR_UPDATE_REF") || return
    gcr_revision_valid "$revision" || { ui_err "invalid upstream revision"; return 1; }
    printf '%s\n' "$revision"
}

gcr_check_update() (
    local revision
    umask 077
    mkdir -p "$GCR_STATE_DIR" || return
    gcr_lock "$GCR_STATE_DIR/check.lock" || return 0
    trap 'gcr_unlock "$GCR_STATE_DIR/check.lock"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    # A queued startup worker may acquire the lock after another check has finished.
    if [ "${1:-}" = --if-due ]; then gcr_check_due || return 0; fi
    # Failed checks are throttled too, so an outage never creates a request storm.
    date +%s > "$GCR_STATE_DIR/checked_at" || return
    if ! revision=$(gcr_latest_revision); then
        printf '%s\n' 'failed' > "$GCR_STATE_DIR/check_result"
        ui_err "version check failed; cached metadata was kept"
        return 1
    fi
    printf '%s\n' "$revision" > "$GCR_STATE_DIR/latest.tmp" || return
    command mv "$GCR_STATE_DIR/latest.tmp" "$GCR_STATE_DIR/latest" || return
    printf '%s\n' 'ok' > "$GCR_STATE_DIR/check_result" || return
    if [ "$AUTO_GCR_UPDATE" = true ]; then
        gcr_read "$GCR_STATE_DIR/revision"
        if [ "$revision" != "$GCR_VALUE" ]; then myupdate --no-restart; fi
    fi
)

gcr_download_release() {
    local revision=$1 staging=$2 file base
    base="$GCR_RAW_URL/$GCR_REPOSITORY/$revision"
    gcr_fetch "$base/manifest.sha256" -o "$staging/manifest.sha256" || return
    while IFS= read -r file; do
        case "$file" in */*) mkdir -p "$staging/${file%/*}" || return ;; esac
        gcr_fetch "$base/$file" -o "$staging/$file" || return
    done <<EOF
$(gcr_payload_files)
EOF
}

gcr_update_files() (
    local revision staging=""
    if [ "$GCR_LIB_DIR" = "$GCR_INSTALL_ROOT/lib" ]; then
        ui_err "this is a source checkout; install it with sh install_gcr.sh before updating"
        return 1
    fi
    umask 077
    mkdir -p "$GCR_STATE_DIR" || return
    gcr_lock "$GCR_STATE_DIR/download.lock" || { ui_err "another GCR update is running"; return 1; }
    trap '[ -z "$staging" ] || command rm -rf "$staging"; gcr_unlock "$GCR_STATE_DIR/download.lock"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    revision=$(gcr_latest_revision) || return
    staging=$(mktemp -d "${TMPDIR:-/tmp}/gcr-release.XXXXXX") || return
    ui_step "downloading GCR revision $revision"
    if ! gcr_download_release "$revision" "$staging"; then
        ui_err "download failed; installed files were not changed"
        return 1
    fi
    gcr_install_payload "$staging" "$revision" || return
    printf '%s\n' "$revision" > "$GCR_STATE_DIR/latest"
    date +%s > "$GCR_STATE_DIR/checked_at"
    ui_ok "GCR updated; the previous installation is available with gcr rollback"
)

myupdate() {
    case "${1:-}" in
        ''|--no-restart) ;;
        *) ui_err "usage: myupdate [--no-restart]"; return 2 ;;
    esac
    if [ "$#" -gt 1 ]; then ui_err "usage: myupdate [--no-restart]"; return 2; fi
    gcr_update_files || return
    if [ "${1:-}" = --no-restart ] || ! ui_interactive; then
        ui_note "restart your shell to load the update"
        return 0
    fi
    if ui_confirm "Restart the shell now to load it?"; then
        if [ -n "${ZSH_VERSION:-}" ]; then exec zsh -l; else exec bash -l; fi
    fi
}
