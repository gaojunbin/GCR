# Conda paths come from JSON; menu labels are never used as environment IDs.
conda_envs() {
    local payload rows name location
    CONDA_ENVS=()
    CONDA_ENV_PATHS=()
    payload=$(conda env list --json) || { ui_err "could not list conda environments"; return 1; }
    rows=$(printf '%s' "$payload" | command python3 -c '
import json, os, sys
for prefix in json.load(sys.stdin)["envs"]:
    if any(char in prefix for char in "\n\r\t"):
        raise SystemExit("Environment paths cannot contain tabs or newlines.")
    print("{}\t{}".format(os.path.basename(prefix) or prefix, prefix))
') || return
    while IFS="$(printf '\t')" read -r name location; do
        [ -n "$location" ] || continue
        CONDA_ENV_PATHS+=("$location")
        if [ "$location" = "${CONDA_PREFIX:-}" ]; then
            CONDA_ENVS+=("$name|active   $location")
        else
            CONDA_ENVS+=("$name|$location")
        fi
    done <<EOF
$rows
EOF
    [ "${#CONDA_ENVS[@]}" -gt 0 ] || { ui_warn "no conda environments found"; return 1; }
}

gcr_conda_selection() {
    local i=0 location
    GCR_CONDA_PATH=""
    for location in "${CONDA_ENV_PATHS[@]}"; do
        i=$((i + 1))
        if [ "$i" -eq "$1" ]; then GCR_CONDA_PATH=$location; return 0; fi
    done
    return 1
}

env() {
    if [ -n "${1:-}" ]; then conda activate "$1"; return; fi
    conda_envs || return
    ui_menu "env" "conda environments" "${CONDA_ENVS[@]}" \
        "deactivate|Leave the current environment" || return
    if [ "$UI_CHOICE" -gt "${#CONDA_ENVS[@]}" ]; then
        conda deactivate || return
        ui_ok "environment deactivated"
    else
        gcr_conda_selection "$UI_CHOICE" || return
        conda activate "$GCR_CONDA_PATH" || return
        ui_ok "activated $GCR_CONDA_PATH"
    fi
}

cenv() {
    local name from="" py
    ui_heading "cenv" "create a conda environment"
    ui_ask "Name"; name=$UI_ANSWER
    [ -n "$name" ] || { ui_err "no name given"; return 1; }
    if conda_envs; then
        ui_menu "cenv" "start from" "fresh|A new environment with its own python" \
            "${CONDA_ENVS[@]}" || return
        if [ "$UI_CHOICE" -gt 1 ]; then
            gcr_conda_selection "$((UI_CHOICE - 1))" || return
            from=$GCR_CONDA_PATH
        fi
    fi
    if [ -n "$from" ]; then
        conda create --name "$name" --clone "$from"
        return
    fi
    ui_ask "Python version" "3.12"; py=$UI_ANSWER
    conda create --name "$name" "python=$py" ipykernel -y || return
    conda run --name "$name" python -m ipykernel install --user --name "$name" || return
    ui_ok "created $name and registered its Python as a Jupyter kernel"
}

denv() {
    conda_envs || return
    ui_menu "denv" "delete a conda environment" "${CONDA_ENVS[@]}" || return
    gcr_conda_selection "$UI_CHOICE" || return
    if [ "$GCR_CONDA_PATH" = "${CONDA_PREFIX:-}" ]; then
        ui_err "deactivate this environment before removing it"; return 1
    fi
    if ui_confirm "Delete $GCR_CONDA_PATH and everything in it?" n; then
        conda remove --prefix "$GCR_CONDA_PATH" --all
    fi
}
