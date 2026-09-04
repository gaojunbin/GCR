# Network installers check downloads and deployment commands before reporting success.

install_vpn() (
    print_section "Install VPN (Clash with Docker)" "green"

    print_text "white" "Docker image: https://hub.docker.com/r/junbingao/clash" "false"
    printf "\n\n"

    print_prompt "Where to save data" "/root"
    read vpn_path
    if [ "${vpn_path}" = "" ];then
        cd /root || return
    else
        cd "${vpn_path}" || return
    fi

    print_info "Creating directory structure..."
    mkdir clash || return
    cd clash || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/clash/docker-compose.yml" "docker-compose.yml" || return
    mkdir clash || return
    cd clash || return

    print_prompt "Subscription link (optional, can configure later)" ""
    read link
    if [ -n "$link" ]; then
        print_info "Downloading configuration..."
        gcr_download_file "$link" config.yaml || return
    fi
    cd .. || return

    print_info "Starting Clash service..."
    gcr_compose_up || return

    printf "\n"
    print_line "green" $(tput cols)
    print_success "VPN installed successfully!"
    printf "\n"
    print_text "yellow" "Next steps:" "false"
    printf "\n"
    printf "  1. Run 'listen_vpn' on local machine to connect\n"
    printf "  2. Use 'startvpn' to start or 'stopvpn' to stop VPN\n"
    printf "  3. Default state: VPN is stopped\n"
)

install_buildvpn() (
    echo 'Old version, recommend to use install_xui instead.'
    echo 'Continue? ([y]/n)? \c'
    read continue_yon
    continue_yon=${continue_yon:-n}
    if [ "${continue_yon}" = "y" ];then
        echo 'Install buildvpn on oversea server.'
        echo 'The content is relatively sensitive in mainland China, so please contact me directly for related repository permissions.'
        git clone git@github.com:gaojunbin/buildvpn-trojan.git $GCR_INSTALL_ROOT/.buildvpn-trojan || return
        cd "$GCR_INSTALL_ROOT/.buildvpn-trojan" || return
        bash ./build.sh || return
        cd "$GCR_INSTALL_ROOT" || return
    else
        echo 'Install buildvpn stoped!'
    fi
)

install_xui() (
    echo 'Install x-ui to build vpn on oversea server.'
    echo 'Recommend to install_nginxproxy first.'
    echo 'More infomation can be seen on https://github.com/FranzKafkaYu/x-ui'
    gcr_run_installer https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh bash
)

install_xrayr() (
    echo 'Install xrayr to build vpn on oversea server.'
    gcr_run_installer https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh bash
)

gcr_root() {
    if [ "$(id -u)" -eq 0 ]; then command "$@"; else command sudo "$@"; fi
}

gcr_install_nvidia() (
    local temporary
    temporary=$(mktemp -d "${TMPDIR:-/tmp}/gcr-nvidia.XXXXXX") || return
    trap 'command rm -rf "$temporary"' EXIT
    gcr_root apt-get install -y ca-certificates gnupg || return
    gcr_fetch https://nvidia.github.io/libnvidia-container/gpgkey -o "$temporary/key" || return
    command gpg --batch --dearmor -o "$temporary/key.gpg" "$temporary/key" || return
    gcr_root tee /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg < "$temporary/key.gpg" >/dev/null || return
    gcr_fetch https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list -o "$temporary/source" || return
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' "$temporary/source" > "$temporary/source.list" || return
    gcr_root tee /etc/apt/sources.list.d/nvidia-container-toolkit.list < "$temporary/source.list" >/dev/null || return
    gcr_root apt-get update || return
    gcr_root apt-get install -y nvidia-container-toolkit || return
    gcr_root nvidia-ctk runtime configure --runtime=docker || return
    gcr_root systemctl restart docker
)

install_docker() (
    local temporary distro suite architecture
    gcr_require apt-get dpkg curl || return
    . /etc/os-release || return
    distro=$ID
    suite=${UBUNTU_CODENAME:-$VERSION_CODENAME}
    case "$distro" in ubuntu|debian) ;; *) ui_err "Docker installation supports Ubuntu and Debian"; return 1 ;; esac
    if command docker compose version >/dev/null 2>&1; then
        ui_ok "Docker and Compose are already installed"
    else
        ui_confirm "Install Docker Engine and the Compose plugin?" || return 1
        temporary=$(mktemp -d "${TMPDIR:-/tmp}/gcr-docker.XXXXXX") || return
        trap 'command rm -rf "$temporary"' EXIT
        gcr_root apt-get update || return
        gcr_root apt-get install -y ca-certificates curl || return
        gcr_root install -m 0755 -d /etc/apt/keyrings || return
        gcr_fetch "https://download.docker.com/linux/$distro/gpg" -o "$temporary/key" || return
        gcr_root tee /etc/apt/keyrings/docker.asc < "$temporary/key" >/dev/null || return
        gcr_root chmod a+r /etc/apt/keyrings/docker.asc || return
        architecture=$(dpkg --print-architecture) || return
        printf 'Types: deb\nURIs: https://download.docker.com/linux/%s\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' "$distro" "$suite" "$architecture" > "$temporary/docker.sources" || return
        gcr_root tee /etc/apt/sources.list.d/docker.sources < "$temporary/docker.sources" >/dev/null || return
        gcr_root apt-get update || return
        gcr_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return
        command docker compose version || return
        ui_ok "Docker Engine and Compose are installed"
    fi
    if ui_confirm "Configure NVIDIA GPU containers?" n; then gcr_install_nvidia || return; fi
)

install_frp() (
    generate_frps_ini() {
        echo -e 'frps listening port (bind_port): \c'
        read bind_port
        echo -e 'dashboard username (dashboard_user): \c'
        read dashboard_user
        echo -e 'dashboard password (dashboard_pwd): \c'
        read dashboard_pwd
        echo -e 'dashboard port (dashboard_port): \c'
        read dashboard_port
        echo -e 'token (tocken): \c'
        read token

        cat > frps.ini <<EOF || return
[common]
#frp listening port
bind_port = $bind_port
kcp_bind_port = $bind_port

#dashboard username
dashboard_user = $dashboard_user

#dashboard password
dashboard_pwd = $dashboard_pwd

#dashboard port; visit http://ip:$dashboard_port
dashboard_port = $dashboard_port

#tocken
token = $token
EOF
        echo "frps.ini has been generated. Please keep the documents properly and do not pass them on."
    }

    generate_frpc_ini() {
        echo -e 'server_addr: \c'
        read server_addr
        echo -e 'server_port: \c'
        read server_port
        echo -e 'token: \c'
        read token

        cat > frpc.ini <<EOF || return
# frpc.ini
[common]
server_addr = $server_addr
server_port = $server_port
token = $token
EOF
        echo -e 'Add new service?(y/n): \c'
        read add_block
        while [[ "$add_block" == "y" || "$add_block" == "Y" ]]; do
            echo -e 'service_name: \c'
            read service_name
            echo -e 'service_local_port: \c'
            read service_local_port
            echo -e 'service_remote_port: \c'
            read service_remote_port

            echo >> frpc.ini
            echo "[$service_name]" >> frpc.ini
            echo "type = tcp" >> frpc.ini
            echo "local_ip = 127.0.0.1" >> frpc.ini
            echo "local_port = $service_local_port" >> frpc.ini
            echo "remote_port = $service_remote_port" >> frpc.ini

            echo -e 'Add new service?(y/n): \c'
            read add_block
        done
        echo "frpc.ini has been generated. Please keep the documents properly and do not pass them on."
    }

    echo 'Intranet Penetration Tool.'
    echo -e 'Choose the Function [Number] you want:'
    echo -e '[1] Server - frps'
    echo -e '[2] Client - frpc'
    echo -e 'input you choose: \c'
    read frp_func_num
    if [ "${frp_func_num}" = 1 ];then
        echo -e 'Where to save data: (default: /root): \c'
        read frps_path
        if [ "${frps_path}" = "" ];then
            cd /root || return
        else
            cd "${frps_path}" || return
        fi
        mkdir frps || return
        cd frps || return
        generate_frps_ini || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/frp/frps/docker-compose.yml" "docker-compose.yml" || return
        gcr_compose_up || return

    elif [ "${frp_func_num}" = 2 ];then
        echo -e 'Where to save data: (default: /root): \c'
        read frpc_path
        if [ "${frpc_path}" = "" ];then
            cd /root || return
        else
            cd "${frpc_path}" || return
        fi
        mkdir frpc || return
        cd frpc || return
        generate_frpc_ini || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/frp/frpc/docker-compose.yml" "docker-compose.yml" || return
        gcr_compose_up || return
    else
        echo 'Invalid Input!'
    fi
)
