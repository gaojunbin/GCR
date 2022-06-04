# cp .ohmyzsh to $HOME
cp .ohmyzsh ~/
cp .p9k.zsh ~/

# Install powerline fonts [optional]
git clone https://github.com/powerline/fonts.git --depth=1 ~/powerline_fonts
cd ~/powerline_fonts
./install.sh
cd ..
rm -rf powerline_fonts

# Install nerd-fonts with homebrew (for macos)
# Homebre install
# If error with network, can ref https://gitee.com/cunkai/HomebrewCN
sudo git clone https://github.com/Homebrew/brew.git /opt/homebrew
echo 'export PATH=$PATH:/opt/homebrew/bin' >> ~/.zshrc
# for more install methods, ref [nerd-fonts repo](https://github.com/ryanoasis/nerd-fonts#font-installation)
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Install oh-my-zsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k ~/.oh-my-zsh/custom/themes/powerlevel10k

# Install zsh-syntax-highlightin, zsh-autosuggestions, zsh-myincr
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/gaojunbin/zsh-myincr.git ~/.oh-my-zsh/custom/plugins/zsh-myincr

# add to .zshrc file
echo -e 'whether to rewrite .zshrc? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    cd ~/
    rm -f .zshrc
    torch .zshrc
    echo 'source ~/.ohmyzsh' >> ~/.zshrc
else
    echo 'source ~/.ohmyzsh' >> ~/.zshrc
fi