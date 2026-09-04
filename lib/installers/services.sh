# Service installers stop on directory, download and deployment failures.

install_server-administration() (
    echo 'This is a toolkit for server administration.'
    git clone https://github.com/gaojunbin/.server-administration.git $GCR_INSTALL_ROOT/.server-administration || return
)

install_nginxproxy() {
    gcr_compose_service "nginx-proxy" \
        "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/nginx-proxy-zh/docker-compose.yml" "81"
}

install_homeweb() (
    echo 'This is a function for installing homeweb of Junbin Gao (junbingao.com)'
    echo 'The repo is private. You must have the keygen to access.'
    echo -e 'Where to save data: (default: /root): \c'
    read homeweb_path
    if [ "${homeweb_path}" = "" ];then
        cd /root || return
    else
        cd "${homeweb_path}" || return
    fi

    git clone git@github.com:gaojunbin/HomeWeb.git --recurse-submodules && cd HomeWeb || return
    docker build -t homeweb:latest . || return

    echo -e 'The port for HomeWeb (default: 80 ): \c'
    read homeweb_port
    if [ "${homeweb_port}" = "" ];then
        docker run -d --rm -p 80:80 -v $PWD:/var/www/html --name homeweb homeweb:latest || return
        echo 'Success! Now you can visit HomeWeb via localhost:80'
    else
        docker run -d --rm -p ${homeweb_port}:80 -v $PWD:/var/www/html --name homeweb homeweb:latest || return
        echo 'Success! Now you can visit HomeWeb.'
    fi
)

install_newtab() (
    echo 'This is a function for installing NewTab of Junbin Gao.'
    echo -e 'Where to save data: (default: /root): \c'
    read homeweb_path
    if [ "${homeweb_path}" = "" ];then
        cd /root || return
    else
        cd "${homeweb_path}" || return
    fi

    git clone https://github.com/gaojunbin/NewTab.git && cd NewTab || return

    gcr_compose_up || return

    echo 'Success! Now you can visit NewTab.'
)

install_deepl() (
    echo -e 'The port for DeepL (default: 11000 ): \c'
    read deepl_port
    if [ "${deepl_port}" = "" ];then
        docker run -d --rm -p 11000:80 junbingao/deepl:latest || return
    else
        docker run -d --rm -p ${deepl_port}:80 junbingao/deepl:latest || return
    fi
)

install_cloudreve() {
    gcr_compose_service "cloudreve" \
        "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/cloudreve/docker-compose.yml" "5212"
}

install_overleaf() (
    echo -e 'Where to save data: (default: /root): \c'
    read overleaf_path
    if [ "${overleaf_path}" = "" ];then
        cd /root || return
    else
        cd "${overleaf_path}" || return
    fi
    mkdir overleaf || return
    cd overleaf || return
    mkdir mongo_data || return
    mkdir redis_data || return
    mkdir sharelatex_data || return
    chmod -R 777 mongo_data  || return
    chmod -R 777 redis_data  || return
    chmod -R 777 sharelatex_data || return

    # Prompt for port number
    echo -e "Enter the local port number for Sharelatex: \c"
    read sharelatex_port

    # Prompt for SHARELATEX_SITE_URL
    echo -e "Enter the value for SHARELATEX_SITE_URL [default: https://overleaf.junbingao.com]: \c"
    read sharelatex_site_url
    sharelatex_site_url=${sharelatex_site_url:-https://overleaf.junbingao.com}

    # Prompt for SHARELATEX_EMAIL_ values
    echo -e "Enter the value for SHARELATEX_EMAIL_FROM_ADDRESS: \c"
    read sharelatex_email_from_address
    echo -e "Enter the value for SHARELATEX_EMAIL_SMTP_HOST: \c"
    read sharelatex_email_smtp_host
    echo -e "Enter the value for SHARELATEX_EMAIL_SMTP_PORT: \c"
    read sharelatex_email_smtp_port
    echo -e "Enter the value for SHARELATEX_EMAIL_SMTP_PASS: \c"
    read sharelatex_email_smtp_pass

    # Generate docker-compose.yml
    cat > docker-compose.yml <<EOF || return
version: '2.2'
services:
    sharelatex:
        restart: always
        image: junbingao/sharelatex:latest
        container_name: sharelatex
        depends_on:
            mongo:
                condition: service_healthy
            redis:
                condition: service_started
        ports:
            - $sharelatex_port:80
        links:
            - mongo
            - redis
        volumes:
            - ./sharelatex_data:/var/lib/sharelatex
            - ./sharelatex_data/register.pug:/overleaf/services/web/app/views/user/register.pug:ro
            - ./sharelatex_data/router.js:/overleaf/services/web/app/src/router.js:ro
            - ./sharelatex_data/UserController.js:/overleaf/services/web/app/src/Features/User/UserController.js:ro
            - ./sharelatex_data/UserPagesController.js:/overleaf/services/web/app/src/Features/User/UserPagesController.js:ro
        environment:
            SHARELATEX_APP_NAME: Overleaf Community Edition
            SHARELATEX_MONGO_URL: mongodb://mongo/sharelatex
            SHARELATEX_REDIS_HOST: redis
            REDIS_HOST: redis
            ENABLED_LINKED_FILE_TYPES: 'url,project_file'
            ENABLE_CONVERSIONS: 'true'
            EMAIL_CONFIRMATION_DISABLED: 'true'
            TEXMFVAR: /var/lib/sharelatex/tmp/texmf-var
            SHARELATEX_SITE_URL: $sharelatex_site_url
            SHARELATEX_EMAIL_FROM_ADDRESS: "$sharelatex_email_from_address"
            SHARELATEX_EMAIL_SMTP_HOST: $sharelatex_email_smtp_host
            SHARELATEX_EMAIL_SMTP_PORT: $sharelatex_email_smtp_port
            SHARELATEX_EMAIL_SMTP_SECURE: 'true'
            SHARELATEX_EMAIL_SMTP_USER: $sharelatex_email_from_address
            SHARELATEX_EMAIL_SMTP_PASS: $sharelatex_email_smtp_pass
            SHARELATEX_EMAIL_SMTP_TLS_REJECT_UNAUTH: 'true'
            SHARELATEX_EMAIL_SMTP_IGNORE_TLS: 'false'

    mongo:
        restart: always
        image: junbingao/mongo:latest
        container_name: mongo
        expose:
            - 27017
        volumes:
            - ./mongo_data:/data/db
        healthcheck:
            test: echo 'db.stats().ok' | mongo localhost:27017/test --quiet
            interval: 10s
            timeout: 10s
            retries: 5

    redis:
        restart: always
        image: junbingao/redis:latest
        container_name: redis
        expose:
            - 6379
        volumes:
            - ./redis_data:/data
EOF

    echo "docker-compose.yml file generated successfully."

    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/overleaf/register.pug" "sharelatex_data/register.pug" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/overleaf/router.js" "sharelatex_data/router.js" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/overleaf/UserController.js" "sharelatex_data/UserController.js" || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/overleaf/UserPagesController.js" "sharelatex_data/UserPagesController.js" || return

    echo 'Congratulations! You have installed overleaf successfully.'
    echo '!!Important!! Please change the invitation code in UserController.js Line 195 like:'
    echo '$ vim sharelatex_data/UserController.js'
    echo 'Then start the service with:'
    echo '$ docker compose up -d'
    echo 'first-admin page: ip:$sharelatex_port/launchpad'
)

install_serverstatus() (
    echo 'Monitor you server status.'
    echo -e 'Choose the Function [Number] you want:'
    echo -e '[1] Single - Ward'
    echo -e '[2] Multiple - ServerStatus'
    echo -e 'input you choose: \c'
    read func_num
    if [ "${func_num}" = 1 ];then
        echo -e 'Where to save data: (default: /root): \c'
        read serverstatus_path
        if [ "${serverstatus_path}" = "" ];then
            cd /root || return
        else
            cd "${serverstatus_path}" || return
        fi
        mkdir ward || return
        cd ward || return
        gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/ward/docker-compose.yml" "docker-compose.yml" || return
        gcr_compose_up || return
        echo 'Success!'
        echo 'Run on port: 4000'
    elif [ "${func_num}" = 2 ];then
        echo 'Have not prepared...'
    else
        echo 'Invalid Input!'
    fi
)

install_chatgpt() (
    echo -e 'Install chat web with chatgpt API.'
    echo -e 'Where to save data: (default: /root): \c'
    read chat_path
    if [ "${chat_path}" = "" ];then
        cd /root || return
    else
        cd "${chat_path}" || return
    fi
    mkdir chatgpt || return
    cd chatgpt || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/chatgpt/docker-compose.yml" "docker-compose.yml" || return
    echo -e 'Please modify the docker compose file as the comments suggesting.'
    echo -e 'Then run $ docker compose up -d'
)

install_webmonitor() (
    echo -e 'Install web monitor to monitor your website.'
    echo -e 'More details: https://github.com/LogicJake/WebMonitor'
    echo -e 'Where to save data: (default: /root): \c'
    read webmonitor_path
    if [ "${webmonitor_path}" = "" ];then
        cd /root || return
    else
        cd "${webmonitor_path}" || return
    fi
    mkdir webmonitor || return
    cd webmonitor || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/webmonitor/docker-compose.yml" "docker-compose.yml" || return
    echo -e 'Please modify the docker compose file as the comments suggesting.'
    echo -e 'Then run $ docker compose up -d'
)

install_vncdocker() (
    echo -e 'Install vnc docker.'
    echo -e 'More details: https://github.com/fcwu/docker-ubuntu-vnc-desktop'
    echo -e 'Where to save data: (default: /root): \c'
    read vnc_path
    if [ "${vnc_path}" = "" ];then
        cd /root || return
    else
        cd "${vnc_path}" || return
    fi
    mkdir vnc || return
    cd vnc || return
    gcr_download_file "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/vnc/docker-compose.yml" "docker-compose.yml" || return
    echo -e 'Please modify the docker compose file as the comments suggesting.'
    echo -e 'Then run $ docker compose up -d'
)

install_qbittorrent() (
    echo -e 'Install qbittorrent.'
    echo -e 'User docker or bash shell? ([d]/b): \c'
    read db
    db=${db:-d}
    if [ "${db}" = "d" ];then
        echo -e 'Where to save data: (default: /root): \c'
        read qbittorrent_path
        if [ "${qbittorrent_path}" = "" ];then
            cd /root || return
        else
            cd "${qbittorrent_path}" || return
        fi
        git clone https://github.com/gaojunbin/qbittorrent.git || return
        cd qbittorrent || return
        gcr_compose_up || return
    elif [ "${db}" = "b" ];then
        echo -e 'set username: \c'
        read username
        echo -e 'set password: \c'
        read password
        gcr_run_installer "https://raw.githubusercontent.com/jerry048/Dedicated-Seedbox/main/Install.sh" bash "$username" "$password" 1024 || return
    else
        echo 'Invalid Input!'
        return 2
    fi
)

install_jellyfin() {
    gcr_compose_service "jellyfin" \
        "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/jellyfin/docker-compose.yml" "8096"
}

install_image() {
    gcr_compose_service "lsky-pro" \
        "https://raw.githubusercontent.com/gaojunbin/ConfigFile/master/lsky-pro/docker-compose.yml" ""
}

install_copypaste() (
    echo -e 'Install copypaste.'
    echo -e 'where to save data: (default: $GCR_INSTALL_ROOT): \c'
    read copypaste_path
    if [ "${copypaste_path}" = "" ];then
        cd "$GCR_INSTALL_ROOT" || return
    else
        mkdir -p ${copypaste_path} || return
        cd "${copypaste_path}" || return
    fi

    echo -e 'set MICROBIN_BASIC_AUTH_USERNAME: \c'
    read MICROBIN_BASIC_AUTH_USERNAME
    echo -e 'set MICROBIN_ADMIN_USERNAME: \c'
    read MICROBIN_ADMIN_USERNAME
    echo -e 'set MICROBIN_ADMIN_PASSWORD: \c'
    read MICROBIN_ADMIN_PASSWORD
    echo -e 'set MICROBIN_PUBLIC_PATH: \c'
    read MICROBIN_PUBLIC_PATH
    echo -e 'set MICROBIN_TITLE: \c'
    read MICROBIN_TITLE
    echo -e 'set MICROBIN_FOOTER_TEXT: \c'
    read MICROBIN_FOOTER_TEXT
    echo -e 'set MICROBIN_PORT: \c'
    read MICROBIN_PORT
    cat > docker-compose.yml <<EOF || return
version: '3'
services:
    microbin:
        image: danielszabo99/microbin:latest
        container_name: microbin
        restart: unless-stopped
        environment:
        - TZ=Asia/Shanghai
        - MICROBIN_BASIC_AUTH_USERNAME=$MICROBIN_BASIC_AUTH_USERNAME
        - MICROBIN_ADMIN_USERNAME=$MICROBIN_ADMIN_USERNAME
        - MICROBIN_ADMIN_PASSWORD=$MICROBIN_ADMIN_PASSWORD
        - MICROBIN_PUBLIC_PATH=$MICROBIN_PUBLIC_PATH
        - MICROBIN_EDITABLE=true
        - MICROBIN_ENCRYPTION_CLIENT_SIDE=true
        - MICROBIN_ENCRYPTION_SERVER_SIDE=true
        - MICROBIN_HIGHLIGHTSYNTAX=true
        - MICROBIN_HASH_IDS=true
        - MICROBIN_HELP=true
        - MICROBIN_SHORT_PATH=true
        - MICROBIN_NO_LISTING=false
        - MICROBIN_QR=true
        - MICROBIN_TITLE=$MICROBIN_TITLE
        - MICROBIN_HIDE_LOGO=true
        - MICROBIN_FOOTER_TEXT=$MICROBIN_FOOTER_TEXT
        ports:
        - $MICROBIN_PORT:8080
        volumes:
        - ./microbin-data:/app/pasta_data
EOF
    gcr_compose_up || return
)
