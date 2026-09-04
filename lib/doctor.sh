gcr_status() {
    ui_heading "GCR status" "$GCR_INSTALL_ROOT"
    gcr_read "$GCR_STATE_DIR/revision"
    ui_field "Installed" "${GCR_VALUE:-local / untracked}"
    gcr_read "$GCR_STATE_DIR/latest"
    ui_field "Upstream" "${GCR_VALUE:-not checked}"
    gcr_read "$GCR_STATE_DIR/check_result"
    ui_field "Last check" "${GCR_VALUE:-not checked}"
    ui_field "Config" "$GCR_CONFIG_FILE"
    if [ -d "$GCR_STATE_DIR/pending" ]; then
        ui_warn "an interrupted update needs recovery: gcr rollback"
    elif [ -d "$GCR_STATE_DIR/previous" ]; then
        ui_note "a previous installation is available: gcr rollback"
    fi
}

gcr_doctor_error() {
    GCR_DOCTOR_ERRORS=$((GCR_DOCTOR_ERRORS + 1))
    ui_err "$1"
    [ -z "${2:-}" ] || ui_command "$2"
}

gcr_doctor_files() {
    local file target
    while IFS= read -r file; do
        case "$file" in
            lib/*) target="$GCR_LIB_DIR/${file#lib/}" ;;
            config/*) target=$GCR_DEFAULTS_FILE ;;
            *) target="$GCR_INSTALL_ROOT/$file" ;;
        esac
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            gcr_doctor_error "broken symlink: $target" "ls -l \"$target\""
        elif [ ! -f "$target" ] || [ ! -r "$target" ]; then
            gcr_doctor_error "missing or unreadable file: $target" "gcr update --no-restart"
        elif [ ! -w "$target" ]; then
            gcr_doctor_error "configuration is not writable: $target" "ls -l \"$target\""
        fi
    done <<EOF
$(gcr_payload_files)
EOF
    if [ -L "$GCR_CONFIG_FILE" ] && [ ! -e "$GCR_CONFIG_FILE" ]; then
        gcr_doctor_error "broken user configuration symlink: $GCR_CONFIG_FILE"
    fi
}

gcr_doctor_paths() {
    local name directory found selected
    for name in zsh bash curl python3 docker conda claude codex cursor-agent grok agy; do
        found=0 selected=""
        while IFS= read -r directory; do
            [ -n "$directory" ] || directory=.
            [ -f "$directory/$name" ] && [ -x "$directory/$name" ] || continue
            found=$((found + 1))
            if [ -z "$selected" ]; then selected="$directory/$name"; fi
        done <<EOF
$(printf '%s' "$PATH" | tr ':' '\n')
EOF
        if [ "$found" -gt 1 ]; then
            ui_warn "$name has $found PATH entries; selected: $selected"
        elif [ "$found" = 1 ]; then
            ui_field "$name" "$selected"
        else
            case "$name" in
                zsh|bash|curl) gcr_doctor_error "required command is missing: $name" ;;
            esac
        fi
    done
}

gcr_doctor_plugins() {
    [ -n "${ZSH_VERSION:-}" ] && [ "$GCR_LOAD_THEME" = true ] || return 0
    local root="$GCR_INSTALL_ROOT/.oh-my-zsh" plugin
    [ ! -d "$GCR_INSTALL_ROOT/oh-my-zsh" ] || root="$GCR_INSTALL_ROOT/oh-my-zsh"
    if [ ! -f "$root/oh-my-zsh.sh" ]; then
        gcr_doctor_error "Oh My Zsh is missing: $root"
        return
    fi
    for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-myincr; do
        if [ ! -f "$root/custom/plugins/$plugin/$plugin.plugin.zsh" ]; then
            gcr_doctor_error "missing plugin: $plugin"
        fi
    done
    if [ ! -f "$root/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]; then
        gcr_doctor_error "Powerlevel10k is missing"
    fi
}

gcr_doctor_kernels() {
    command -v conda >/dev/null 2>&1 && command -v jupyter >/dev/null 2>&1 &&
        command -v python3 >/dev/null 2>&1 || return 0
    local environments kernels report
    environments=$(conda env list --json) || { gcr_doctor_error "Conda environment listing failed"; return; }
    kernels=$(command jupyter kernelspec list --json) || {
        gcr_doctor_error "Jupyter kernel listing failed"; return
    }
    report=$(command python3 -c '
import json, os, sys
envs = json.loads(sys.argv[1])["envs"]
kernels = json.loads(sys.argv[2])["kernelspecs"]
for name, entry in kernels.items():
    argv = entry["spec"].get("argv", [])
    executable = argv[0] if argv else ""
    matches = [p for p in envs if os.path.basename(p) == name]
    if os.path.isabs(executable) and not os.access(executable, os.X_OK):
        print("{}: interpreter is missing: {}".format(name, executable))
    elif len(matches) == 1 and os.path.realpath(executable) != os.path.realpath(os.path.join(matches[0], "bin/python")):
        print("{}: interpreter does not match environment {}".format(name, matches[0]))
' "$environments" "$kernels") || { gcr_doctor_error "invalid Conda or Jupyter metadata"; return; }
    if [ -n "$report" ]; then
        gcr_doctor_error "$report"
        ui_note 'register again with: conda run -n NAME python -m ipykernel install --user --name NAME'
    else
        ui_ok "Jupyter kernel interpreters match their environments"
    fi
}

gcr_doctor() {
    GCR_DOCTOR_ERRORS=0
    ui_heading "GCR doctor" "read-only local diagnostics"
    gcr_doctor_files
    gcr_doctor_paths
    gcr_doctor_plugins
    gcr_doctor_kernels
    if [ -d "$GCR_STATE_DIR/pending" ]; then
        gcr_doctor_error "an interrupted update needs recovery" "gcr rollback"
    fi
    ui_field "Configuration" "$GCR_CONFIG_FILE"
    if [ "$GCR_DOCTOR_ERRORS" -eq 0 ]; then
        ui_ok "no blocking problems found"
    else
        ui_err "$GCR_DOCTOR_ERRORS problem(s) need attention"
        return 1
    fi
}
