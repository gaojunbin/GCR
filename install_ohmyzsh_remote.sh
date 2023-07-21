git clone https://github.com/gaojunbin/GCR.git ~/GCR
cd ~/GCR

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
    sudo apt install zsh -y
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
    sudo chsh -s $(which zsh) $(whoami)
fi

# add start zsh to bashrc
echo -e "Add starting zsh in .bashrc? (y/[n])? \c"

read yon
yon=${yon:-n}

if [ "${yon}" = "y" ];then
    echo '# [Added by install_ohmyzsh_remote.ssh] starting zsh when starting.' >> ~/.bashrc
    echo 'zsh' >> ~/.bashrc
fi

echo -e "Installing for ohmyzsh complete! Now you can resart shell."

cd
rm -rf ~/GCR