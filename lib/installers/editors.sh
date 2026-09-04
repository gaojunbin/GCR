# Editor installers run in subshells to preserve the working directory.

install_colorls() (
    echo "This is a function to install colorls, as well as ruby 3.1.2."
    echo "Note: If you have the root permission, suggest to install/update ruby your self, then run this function."
    echo "Because this function install ruby without root only for $USER."
    echo -e "Do you have ruby >= 2.6? ([y]/n)? \c"
    read yon
    if [ "${yon}" = "y" ];then
        gem install colorls || return
    else
        echo -e "Do you want to install ruby-3.1? ([y]/n)? \c"
        read install_yon
        if [ "${install_yon}" = "y" ];then
            mkdir "$GCR_INSTALL_ROOT/colorls_tmp" || return
            cd "$GCR_INSTALL_ROOT/colorls_tmp" || return
            wget https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.2.tar.gz || return
            extract ruby-3.1.2.tar.gz || return
            cd ruby-3.1.2 || return
            ./configure --prefix="$GCR_INSTALL_ROOT/.ruby" || return
            make && make install || return
            export PATH=$GCR_INSTALL_ROOT/.ruby/bin:$PATH
            echo "may have error in install ruby - openssl!"
            gem install colorls || return
            cd "$GCR_INSTALL_ROOT" || return
            command rm -rf "$GCR_INSTALL_ROOT/colorls_tmp" || return
        else
            echo 'Install colorls stoped! You must install ruby >= 2.6 first.'
        fi
    fi
)

install_spacevim() (
    echo "This is a function to install SpaceVim, as well as vim latest."
    echo "SpaceVim makes vim powerful!"
    echo "Note: SpaceVim need new version of vim!"
    echo -e "Install vim latest from source or not? ([y]/n)? \c"
    read yon
    if [ "${yon}" = "y" ];then
       git clone https://github.com/vim/vim.git "$GCR_INSTALL_ROOT/.vim-source" || return
       cd "$GCR_INSTALL_ROOT/.vim-source/src" || return
       make || return
       gcr_save_path "$GCR_INSTALL_ROOT/.vim-source/src" || return
       ui_note "restart your shell to load the configuration"
    fi
    gcr_run_installer "https://spacevim.org/cn/install.sh" bash --install vim || return
    echo "See more information via type:"
    echo "$ curl -sLf https://spacevim.org/cn/install.sh | bash -s -- -h"
)

install_discard_vim() (
    print_text "green" "Install discard-vim." "false"
    printf "\n"
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/discard-vim/rmate" "$GCR_INSTALL_ROOT/.rmate" || return
    chmod +x "$GCR_INSTALL_ROOT/.rmate" || return
    if [ -z "$RmatePort" ]; then
        print_text "green" "Input the RmatePort (default: 52698): " "false"
        read -r RmatePort || return
        RmatePort=${RmatePort:-52698}
        # if RmatePort is not used
        while ! gcr_number "$RmatePort" || [ "$RmatePort" -gt 65535 ] || lsof -i:"$RmatePort"; do
            print_text "red" "$RmatePort is used. Please input another port: " "false"
            read -r RmatePort || return
            RmatePort=${RmatePort:-52698}
        done
        gcr_save_setting RmatePort "$RmatePort" || return
    fi

    print_text "green" "Install discard-vim successfully. Please restart your terminal." "true"
    printf "\n"
    print_text "green" "You also need:" "false"
    printf "\n"
    print_text "cyan" "1. Add the following configuration to your SSH configuration file:" "false"
    printf "\n"
    print_text "yellow" "# -------- Rmate configuration --------
Host *
    RemoteForward ${RmatePort} 127.0.0.1:52698" "false"
    printf "\n"
    print_text "cyan" "2. Install the plug-in on your local computer as follows:" "false"
    printf "\n"
    print_text "cyan" "1) For Sublime Text Users:" "false"
    printf "\n"
    echo "- Install the package 'rsub' via Package Control."
    echo "  Press Cmd + Shift + P for Mac, select Package Control: Install Package, and, finally, select rsub."
    print_text "cyan" "2) For VSCode Users:" "false"
    printf "\n"
    echo "- Install the extension Remote VSCode via the Extensions Marketplace."
    echo "  Press Cmd + Shift + P for Mac and Open User Sttings, and add the following configuration:"
    print_text "yellow" "//-------- Remote VSCode configuration --------
"remote.port": 52698
"remote.onstartup": true
"remote.host": "127.0.0.1"
"remote.dontShowPortAlreadyInUseError": false
//-------- Remote VSCode configuration --------" "false"
    printf "\n"
)

install_joshuto() (
    print_section "Install joshuto - Modern File Browser" "green"

    print_text "white" "A ranger-like terminal file manager written in Rust" "false"
    printf "\n\n"

    print_text "cyan" "Universal Systems:" "false"
    printf "\n"
    print_menu_option "1" "Ubuntu" "Build from source"
    print_menu_option "2" "MacOS" "Install via Homebrew"

    printf "\n"
    print_text "cyan" "Specific Systems:" "false"
    printf "\n"
    print_menu_option "3" "NUS HPC" "Pre-built binary"
    print_menu_option "4" "NSCC" "Pre-built binary"

    printf "\n"
    print_prompt "Select your OS" "1"
    read install_os
    install_os=${install_os:-1}

    if [ "${install_os}" = 1 ]; then
        print_info "Installing Rust toolchain..."
        gcr_run_installer "https://sh.rustup.rs" sh || return
        . "${CARGO_HOME:-$HOME/.cargo}/env" || return

        print_info "Cloning joshuto repository..."
        git clone https://github.com/kamiyaa/joshuto.git "$GCR_INSTALL_ROOT/.joshuto" || return
        cd "$GCR_INSTALL_ROOT/.joshuto" || return

        print_info "Building from source (this may take a while)..."
        cargo build --release || return

    elif [ "${install_os}" = 2 ]; then
        print_info "Installing via Homebrew..."
        brew install joshuto || return

    elif [ "${install_os}" = 3 ] || [ "${install_os}" = 4 ]; then
        print_info "Downloading pre-built binary..."
        mkdir -p "$GCR_INSTALL_ROOT/.joshuto/target/release" || return
        cd "$GCR_INSTALL_ROOT/.joshuto/target/release" || return
        wget https://github.com/kamiyaa/joshuto/releases/download/v0.9.8/joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz || return
        tar -xzf joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz || return
        mv joshuto-v0.9.8-x86_64-unknown-linux-musl/joshuto ./ || return
        command rm -rf joshuto-v0.9.8-x86_64-unknown-linux-musl joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz || return
    else
        ui_err "invalid operating system selection"; return 2
    fi

    print_info "Downloading configuration files..."
    mkdir -p "$GCR_INSTALL_ROOT/.config/joshuto" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/icons.toml" "$GCR_INSTALL_ROOT/.config/joshuto/icons.toml" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/joshuto.toml" "$GCR_INSTALL_ROOT/.config/joshuto/joshuto.toml" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/keymap.toml" "$GCR_INSTALL_ROOT/.config/joshuto/keymap.toml" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/mimetype.toml" "$GCR_INSTALL_ROOT/.config/joshuto/mimetype.toml" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/preview_file.sh" "$GCR_INSTALL_ROOT/.config/joshuto/preview_file.sh" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/theme.toml" "$GCR_INSTALL_ROOT/.config/joshuto/theme.toml" || return
    chmod +x "$GCR_INSTALL_ROOT/.config/joshuto/preview_file.sh" || return

    printf "\n"
    print_line "green" $(tput cols)
    print_success "joshuto installed successfully!"
    printf "\n"
    print_text "yellow" "Please restart your terminal to use joshuto" "false"
    printf "\n"
)

update_joshuto() (
    if command -v joshuto >/dev/null 2>&1 || [[ -f $GCR_INSTALL_ROOT/.joshuto/target/release/joshuto ]]; then
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/icons.toml" "$GCR_INSTALL_ROOT/.config/joshuto/icons.toml" || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/joshuto.toml" "$GCR_INSTALL_ROOT/.config/joshuto/joshuto.toml" || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/keymap.toml" "$GCR_INSTALL_ROOT/.config/joshuto/keymap.toml" || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/mimetype.toml" "$GCR_INSTALL_ROOT/.config/joshuto/mimetype.toml" || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/preview_file.sh" "$GCR_INSTALL_ROOT/.config/joshuto/preview_file.sh" || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/joshuto/theme.toml" "$GCR_INSTALL_ROOT/.config/joshuto/theme.toml" || return
        chmod +x "$GCR_INSTALL_ROOT/.config/joshuto/preview_file.sh" || return
    fi
)
