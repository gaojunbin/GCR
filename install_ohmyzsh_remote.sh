cd ~/GCR
# mv to $HOME
cp .ohmyshell ~/
cp .ohmyzsh ~/
cp .p9k.zsh ~/
cp -r oh-my-zsh ~/.oh-my-zsh

# add to .zshrc file
echo -e 'whether to rewrite .zshrc? ([y]/n)? \c'
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