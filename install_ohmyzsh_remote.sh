git clone https://github.com/gaojunbin/GCR.git ~/GCR
cd ~/GCR

# is root?
echo -e "Are you in the root group? ([y]/n)? \c"
read root_yon
root_yon=${root_yon:-y}

# uninstall old version
echo -e "Uninstall old version? ([y]/n)? \c"

read yon
you=${yon:-y}

if [ "${yon}" = "y" ];then
    rm -rf ~/.ohmyshell
    rm -rf ~/.ohmytool
    rm -rf ~/.ohmyzsh
    rm -rf ~/.p9k.zsh
    rm -rf ~/.oh-my-zsh
fi

# mv to $HOME
cp .ohmyshell ~/
cp .ohmytool ~/
cp .ohmyzsh ~/
cp .p9k.zsh ~/
cp -r oh-my-zsh ~/.oh-my-zsh

# install zsh
echo -e "Install zsh? ([y]/n)? \c"

read yon
yon=${yon:-y}

if [ "${yon}" = "y" ];then
    if [ "${root_yon}" = "y" ];then
        sudo apt install zsh -y
    else
        cd
        wget -O zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download --no-check-certificate
        mkdir zsh && unxz zsh.tar.xz && tar -xvf zsh.tar -C zsh --strip-components 1
        cd zsh
        ./configure --prefix=$HOME/zsh
        make && make install
        echo 'export PATH=$HOME/zsh/bin:$PATH' >> ~/.bash_profile
        rm ~/zsh.tar.xz
        cd ~/GCR
    fi
fi

# add to .zshrc file
echo -e "Rewrite .zshrc? ([y]/n)? \c"

read yon
yon=${yon:-y}

if [ "${yon}" = "y" ];then
    cd ~/
    rm -f .zshrc
    touch .zshrc
    echo 'source ~/.ohmyzsh' >> ~/.zshrc
    echo 'source ~/.p9k.zsh' >> ~/.zshrc
    echo 'source ~/.ohmyshell' >> ~/.zshrc
else
    echo 'source ~/.ohmyzsh' >> ~/.zshrc
    echo 'source ~/.p9k.zsh' >> ~/.zshrc
    echo 'source ~/.ohmyshell' >> ~/.zshrc
fi

# set zsh as default
echo -e "Set zsh as default? ([y]/n)? \c"

read yon
yon=${yon:-y}

if [ "${yon}" = "y" ];then
    if [ "${root_yon}" = "y" ];then
        sudo chsh -s $(which zsh) $(whoami)
    else
        echo '# [Added by install_ohmyzsh_remote.ssh] starting zsh when log in.' >> ~/.bash_profile
        echo 'export SHELL=$HOME/zsh/bin/zsh' >> ~/.bash_profile
        echo 'exec $HOME/zsh/bin/zsh -l' >> ~/.bash_profile
    fi
fi

echo -e "Installing for ohmyzsh complete! Now you can restart shell."

cd
rm -rf ~/GCR