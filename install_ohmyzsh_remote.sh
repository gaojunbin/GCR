cd ~/GCR
# mv to $HOME
cp .ohmyshell ~/
cp .ohmyzsh ~/
cp .p9k.zsh ~/
cp -r oh-my-zsh ~/.oh-my-zsh

# install zsh
echo 'whether to install zsh? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    sudo apt install zsh -y
fi

# add to .zshrc file
echo 'whether to rewrite .zshrc? ([y]/n)? \c'
read yon
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
echo 'whether to set zsh as default? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    chsh -s /bin/zsh
fi

# add start zsh to bashrc
echo 'whether to add starting zsh in .bashrc? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    echo '# [Added by install_ohmyzsh_remote.ssh] starting zsh when starting.' >> ~/.bashrc
    echo 'zsh' >> ~/.bashrc
fi

echo 'Installing for ohmyzsh complete! Now you can resart shell and run:'
echo 'rm -rf ~/GCR'