# Command-line tool installers run in subshells to preserve the working directory.

install_trzsz() (
    print_section "Install trzsz - File Transfer Tool" "green"

    print_text "white" "A simple and efficient file transfer tool for terminal" "false"
    printf "\n\n"

    print_text "cyan" "Select your operating system:" "false"
    printf "\n"
    print_menu_option "1" "MacOS" ""
    print_menu_option "2" "Ubuntu" ""
    print_menu_option "3" "Debian" "(Beta)"
    print_menu_option "4" "Windows" "(Beta)"
    print_menu_option "5" "Other" "Visit https://trzsz.github.io/cn/go"
    printf "\n"

    print_prompt "Your choice" ""
    read -r os_num || return
    if [ "${os_num}" = 1 ];then
        print_text "cyan" "Installation method:" "false"
        printf "\n"
        print_menu_option "1" "Homebrew" "(Recommended)"
        printf "\n"
        print_prompt "Your choice" "1"
        read method_num
        method_num=${method_num:-1}
        if [ "${method_num}" = 1 ];then
            print_info "Installing with Homebrew..."
            brew update || return
            brew install trzsz-go || return
            print_success "Installation completed!"
        else
            print_error "Invalid input!"; return 2
        fi

    elif [ "${os_num}" = 2 ];then
        print_text "cyan" "Installation method:" "false"
        printf "\n"
        print_menu_option "1" "APT with sudo" ""
        print_menu_option "2" "GitHub release" "(without sudo)"
        printf "\n"
        print_prompt "Your choice" "1"
        read method_num
        method_num=${method_num:-1}
        if [ "${method_num}" = 1 ];then
            print_info "Installing with APT..."
            sudo apt update && sudo apt install software-properties-common || return
            sudo add-apt-repository ppa:trzsz/ppa && sudo apt update || return
            sudo apt install trzsz || return
            print_success "Installation completed!"
        elif [ "${method_num}" = 2 ];then
            print_info "Downloading from GitHub..."
            gcr_download_file "https://github.com/trzsz/trzsz-go/releases/download/v1.1.7/trzsz_1.1.7_linux_x86_64.tar.gz" trzsz_1.1.7_linux_x86_64.tar.gz || return
            tar -xzvf trzsz_1.1.7_linux_x86_64.tar.gz || return
            command rm trzsz_1.1.7_linux_x86_64.tar.gz || return
            mv trzsz_1.1.7_linux_x86_64 "$GCR_INSTALL_ROOT/.trzsz" || return
            gcr_save_path "$GCR_INSTALL_ROOT/.trzsz" || return
            print_success "Installation completed!"
        else
            print_error "Invalid input!"; return 2
        fi

    elif [ "${os_num}" = 3 ];then
        print_text "cyan" "Installation method:" "false"
        printf "\n"
        print_menu_option "1" "APT with sudo" "(Recommended)"
        print_menu_option "2" "pip" ""
        printf "\n"
        print_prompt "Your choice" "1"
        read method_num
        method_num=${method_num:-1}
        if [ "${method_num}" = 1 ];then
            print_info "Installing with APT..."
            sudo apt install curl gpg || return
            local signing_key
            signing_key=$(mktemp "${TMPDIR:-/tmp}/gcr-trzsz-key.XXXXXX") || return
            trap 'command rm -f "$signing_key"' EXIT
            gcr_fetch 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x7074ce75da7cc691c1ae1a7c7e51d1ad956055ca' -o "$signing_key" || return
            sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/trzsz.gpg "$signing_key" || return
            echo 'deb [signed-by=/usr/share/keyrings/trzsz.gpg] https://ppa.launchpadcontent.net/trzsz/ppa/ubuntu jammy main' | sudo tee /etc/apt/sources.list.d/trzsz.list || return
            sudo apt update || return
            sudo apt install trzsz || return
            print_success "Installation completed!"
        elif [ "${method_num}" = 2 ];then
            print_info "Installing with pip..."
            pip install trzsz || return
            print_success "Installation completed!"
        else
            print_error "Invalid input!"; return 2
        fi

    elif [ "${os_num}" = 4 ];then
        print_info "Installing with scoop (https://scoop.sh)..."
        scoop bucket add extras || return
        scoop update || return
        scoop install trzsz || return
        print_success "Installation completed!"

    elif [ "${os_num}" = 5 ];then
        print_info "Please visit https://trzsz.github.io/cn/go for installation instructions"

    else
        print_error "Invalid input!"; return 2
    fi
)

install_tssh() (
    echo 'A ssh client that supports trzsz. (https://github.com/trzsz/trzsz-ssh)'
    echo -e 'Choose the OS [Number] you use now:'
    echo -e '[1] MacOS'
    echo -e '[2] Ubuntu'
    echo -e '[3] Windows (Beta)'
    echo -e 'input you choose: \c'
    read -r os_num || return
    if [ "${os_num}" = 1 ];then
        echo "Install with homebrew..."
        brew update || return
        brew install trzsz-ssh || return
    elif [ "${os_num}" = 2 ];then
        echo "Install with apt..."
        sudo apt update && sudo apt install software-properties-common || return
        sudo add-apt-repository ppa:trzsz/ppa && sudo apt update || return
        sudo apt install tssh || return
    elif [ "${os_num}" = 3 ];then
        echo "Install with scoop... (https://scoop.sh)"
        scoop bucket add extras || return
        scoop update || return
        scoop install tssh || return
    else
        ui_err 'invalid input'; return 2
    fi
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/tssh_conf/.tssh.conf" "$GCR_INSTALL_ROOT/.tssh.conf" || return
)

install_PBShelper() (
    echo -e 'Install PBS helper.'
    git clone https://github.com/gaojunbin/PBShelper.git "$GCR_INSTALL_ROOT/.PBShelper" || return
)

install_htop_wo_sudo() (
    echo -e 'Install htop without sudo.'
    echo -e 'where to save data: (default: $GCR_INSTALL_ROOT): \c'
    read htop_path
    if [ "${htop_path}" = "" ];then
        cd "$GCR_INSTALL_ROOT" || return
    else
        cd "${htop_path}" || return
    fi
    mkdir htop || return
    cd htop || return
    gcr_download_file "https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/h/htop-2.2.0-3.el7.x86_64.rpm" htop.rpm || return
    rpm2cpio htop.rpm > htop.cpio || return
    cpio -idvm < htop.cpio || return

    if [ -n "${shell_file}" ];then
        gcr_save_path "$PWD/usr/bin" || return
        ui_note "restart your shell to load the configuration"
    fi
)

install_autojump() (
    local temporary
    if [ -x "$GCR_INSTALL_ROOT/.autojump/bin/autojump" ]; then
        ui_ok "autojump is already installed"; return 0
    fi
    temporary=$(mktemp -d "${TMPDIR:-/tmp}/gcr-autojump.XXXXXX") || return
    trap 'command rm -rf "$temporary"' EXIT
    git clone --depth 1 https://github.com/wting/autojump.git "$temporary/source" || return
    cd "$temporary/source" || return
    command python3 install.py || return
    ui_ok "autojump installed"
)

install_fzf() (
    echo -e 'Install fzf for zsh-interactive-cd.'
    if [ ! -d "$GCR_INSTALL_ROOT/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$GCR_INSTALL_ROOT/.fzf" || return
    fi
    "$GCR_INSTALL_ROOT/.fzf/install"
)

install_safe_rm() (
    print_section "Install safe-rm - Safe Deletion Tool" "green"

    print_text "white" "Protect your files by moving deleted items to trash instead of permanent removal" "false"
    printf "\n\n"

    print_info "Downloading safe-rm script..."
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/safe-rm/safe-rm" "$GCR_INSTALL_ROOT/.safe-rm" || return
    chmod +x "$GCR_INSTALL_ROOT/.safe-rm" || return

    print_prompt "Trash directory location" "$GCR_INSTALL_ROOT/.Trash"
    read -r safe_rm_path || return
    safe_rm_path=${safe_rm_path:-$GCR_INSTALL_ROOT/.Trash}

    print_info "Configuring environment..."
    gcr_save_setting SAFE_RM_TRASH "$safe_rm_path" || return

    printf "\n"
    print_line "green" $(tput cols)
    print_success "safe-rm installed successfully!"
    printf "\n"
    print_text "yellow" "Please restart your terminal to activate safe-rm" "false"
    printf "\n"
)

update_PBShelper() (
    if [ -d "$GCR_INSTALL_ROOT/.PBShelper" ];then
        cd "$GCR_INSTALL_ROOT/.PBShelper" || return
        git pull https://github.com/gaojunbin/PBShelper.git || return
        cd "$GCR_INSTALL_ROOT" || return
    fi
)

update_tssh() (
    if [ -f "$GCR_INSTALL_ROOT/.tssh.conf" ];then
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/tssh_conf/.tssh.conf" "$GCR_INSTALL_ROOT/.tssh.conf" || return
    fi
)

update_safe_rm() (
    local temporary target="$GCR_INSTALL_ROOT/.safe-rm"
    [ -f "$target" ] || return 0
    temporary=$(mktemp "${TMPDIR:-/tmp}/gcr-saferm.XXXXXX") || return
    trap 'command rm -f "$temporary"' EXIT
    gcr_fetch "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/safe-rm/safe-rm" -o "$temporary" || return
    if command cmp -s "$temporary" "$target"; then ui_ok "safe-rm is up to date"; return 0; fi
    command cat "$temporary" > "$target" || return
    chmod +x "$target" || return
    ui_ok "safe-rm updated"
)
