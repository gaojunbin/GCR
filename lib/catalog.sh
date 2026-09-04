# name | categories | description | operating systems | installed probe | dependencies
GCR_TOOL_CATALOG='install_aicoding|aicoding|Install or update AI coding agents|Darwin,Linux|none|curl
install_base|base|Essential command-line tools|Darwin,Linux|none|git,curl
new_vps_help|base|Recommended sequence for new servers|Darwin,Linux|none|
install_spacevim|dev|Enhanced Vim editor|Darwin,Linux|none|git,curl
install_discard_vim|dev|Remote editing with VS Code or Sublime|Darwin,Linux|file:.rmate|curl
install_autojump|dev|Smart directory navigation|Darwin,Linux|file:.autojump/bin/autojump|git,python3
install_fzf|dev|Command-line fuzzy finder|Darwin,Linux|command:fzf|git
install_htop_wo_sudo|dev,system|Process monitor without sudo|Linux|command:htop|curl,rpm2cpio,cpio
install_joshuto|dev,files|Terminal file browser|Darwin,Linux|command:joshuto|curl,git
install_docker|infra|Docker Engine and Compose plugin|Linux|compose|curl
install_nginxproxy|infra|Nginx Proxy Manager|Linux|none|curl,docker
install_frp|infra|Fast reverse proxy|Linux|none|curl,docker
install_vpn|vpn|Clash VPN with Docker|Linux|none|curl,docker
install_buildvpn|vpn|VPN for overseas servers|Linux|none|git
install_xui|vpn|X-UI VPN panel|Linux|none|curl
install_xrayr|vpn|XrayR VPN solution|Linux|none|curl
install_trzsz|files|File transfer with trz and tsz|Darwin,Linux|command:tsz|curl
install_tssh|files|SSH client with trzsz support|Darwin,Linux|command:tssh|curl
install_safe_rm|files|Safe deletion with a trash directory|Darwin,Linux|file:.safe-rm|curl
install_homeweb|web|Personal homepage|Linux|none|git,docker
install_newtab|web|Browser new tab page|Linux|none|git,docker
install_deepl|web|DeepL translation service|Linux|none|docker
install_chatgpt|web|ChatGPT web interface|Linux|none|curl
install_cloudreve|media|Private cloud storage|Linux|none|curl,docker
install_qbittorrent|media|BitTorrent client|Linux|none|git,docker
install_jellyfin|media|Media streaming server|Linux|none|curl,docker
install_image|media|Lsky-pro image hosting|Linux|none|curl,docker
install_overleaf|productivity|LaTeX collaboration platform|Linux|none|curl
install_copypaste|productivity|Text sharing service|Linux|none|docker
install_webmonitor|productivity|Website uptime monitoring|Linux|none|curl
install_serverstatus|productivity|Server status monitoring|Linux|none|curl,docker
install_vncdocker|productivity|VNC remote desktop|Linux|none|curl
install_PBShelper|system|PBS cluster job helpers|Linux|directory:.PBShelper|git
install_server-administration|system|Server administration toolkit|Linux|directory:.server-administration|git
install_colorls|system|Colorful ls with Ruby|Darwin,Linux|command:colorls|'

_ohmytool_categories() {
    printf '%s\n' \
        'aicoding|AI Coding Agents' 'base|Essential Tools' 'dev|Development Tools' \
        'infra|Infrastructure' 'vpn|Network and Proxy' 'files|File Management' \
        'web|Web Applications' 'media|Storage and Media' \
        'productivity|Productivity and Monitoring' 'system|System and Research'
}

_ohmytool_title() {
    local name description
    while IFS='|' read -r name description; do
        if [ "$name" = "$1" ]; then printf '%s\n' "$description"; return; fi
    done <<EOF
$(_ohmytool_categories)
EOF
}

_ohmytool_items() {
    local name categories description platforms probe dependencies
    while IFS='|' read -r name categories description platforms probe dependencies; do
        case ",$categories," in
            *",$1,"*) printf '%s|%s\n' "$name" "$description" ;;
        esac
    done <<EOF
$GCR_TOOL_CATALOG
EOF
}
