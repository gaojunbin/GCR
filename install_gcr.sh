#!/bin/bash
git clone https://github.com/gaojunbin/GCR.git $HOME/GCR
cd $HOME/GCR

source .ohmyprint

# Welcome message
print_table_text "Welcome to install JUNBIN GCR!" "false" "yellow" "red" $(tput cols)

# Select OS
print_text "white" "Supported operating systems:" "false"
printf "\n"
print_text "yellow" "(Universal system)" "false"
printf "\n"
print_text "green" "[1] Ubuntu (w/ sudo)" "false"
printf "\n"
print_text "green" "[2] Ubuntu (w/o sudo)" "false"
printf "\n"
print_text "green" "[3] MacOS" "false"
printf "\n"
print_text "yellow" "(Specific system)" "false"
printf "\n"
print_text "green" "[4] NUS HPC" "false"
printf "\n"
print_text "green" "[5] NSCC" "false"
printf "\n"
print_text "white" "Plese select your OS: " "false"
read install_gcr_os
install_gcr_os=${install_gcr_os:-1}

print_text "cyan" "Start copying configuration files..." "false"
printf "\n"
# mv to $HOME
cp .ohmyshell ~/
cp .ohmytool ~/
cp .ohmyzsh ~/
cp .p9k.zsh ~/
cp .ohmyprint ~/
cp -r oh-my-zsh ~/.oh-my-zsh

print_text "cyan" "Start Installing zsh..." "false"
printf "\n"
# Install zsh and set zsh as default shell
if [ "${install_gcr_os}" = 1 ];then
    # Ubuntu w/ sudo
    sudo apt install zsh -y
    sudo chsh -s $(which zsh) $(whoami)
fi

if [ "${install_gcr_os}" = 2 ] || [ "${install_gcr_os}" = 4 ] || [ "${install_gcr_os}" = 5 ]; then
    # Ubuntu/hpc/nscc w/o sudo
    if [ ! -e "$HOME/zsh/bin/zsh" ]; then
        tar -xf zsh/zsh-5.9.tar.xz -C $HOME/zsh
        cd $HOME/zsh && ./configure --prefix=$HOME/zsh
        make && make install
        echo '# [Added By GCR]' >> ~/.bash_profile
        echo 'export PATH=$HOME/zsh/bin:$PATH' >> ~/.bash_profile
        echo 'export SHELL=$HOME/zsh/bin/zsh' >> ~/.bash_profile
        echo 'exec $HOME/zsh/bin/zsh -l' >> ~/.bash_profile
        echo '# [Added By GCR]' >> ~/.bash_profile
        cd $HOME/GCR
    fi
fi

print_text "cyan" "Start generating zshrc file..." "false"
printf "\n"
# add to .zshrc file
if [ -e "$HOME/.zshrc" ]; then
    print_text "green" "~/.zshrc already exists:" "false"
    print_text "green" "========================" "false"
    cat ~/.zshrc
    print_text "green" "========================" "false"
    print_text "green" "Rewrite .zshrc? ([y]/n)? " "false"
    read yon
    yon=${yon:-y}

    if [ "${yon}" = "y" ];then
        rm -f ~/.zshrc
    fi
    unset yon
fi

echo '# [ Added By GCR ]' >> ~/.zshrc
echo SHOW_GCR_INFO="false" >> ~/.zshrc
echo CHECK_GCR_UPDATE="true" >> ~/.zshrc
echo 'source ~/.ohmyzsh' >> ~/.zshrc
echo 'source ~/.p9k.zsh' >> ~/.zshrc
echo 'source ~/.ohmyshell' >> ~/.zshrc
echo '# [ Added By GCR ]' >> ~/.zshrc

# specfic for nscc
if [ "${install_gcr_os}" = 5 ]; then
    cp .zsh4nscc ~/
    echo 'source ~/.zsh4nscc' >> ~/.zshrc
fi

# Sucess message
print_table_text "Successful! Please restart the shell!!" "yes" "yellow" "red" $(tput cols)

cd
rm -rf $HOME/GCR
