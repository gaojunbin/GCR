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
print_text "green" "[4] NUS HPC / Medicine HPC" "false"
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


if [ "${install_gcr_os}" = 2 ] || [ "${install_gcr_os}" = 4 ]; then
    # Ubuntu/hpc w/o sudo
    if [ ! -e "$HOME/zsh/bin/zsh" ]; then
        mkdir -p $HOME/zsh && tar -xf zsh/zsh-5.9.tar.xz -C $HOME
        cd $HOME/zsh && ./configure --prefix=$HOME/zsh
        make && make install
        if ! grep -q 'export PATH=\$HOME/zsh/bin:\$PATH' ~/.bash_profile; then
            echo '# [Added By GCR]' >> ~/.bash_profile
            echo 'export PATH=$HOME/zsh/bin:$PATH' >> ~/.bash_profile
        fi
        if ! grep -q 'export SHELL=\$HOME/zsh/bin/zsh' ~/.bash_profile; then
            echo '# [Added By GCR]' >> ~/.bash_profile
            echo 'export SHELL=$HOME/zsh/bin/zsh' >> ~/.bash_profile
        fi
        if ! grep -q '\[ -f \$HOME/zsh/bin/zsh \] && exec \$HOME/zsh/bin/zsh -l' ~/.bash_profile; then
            echo '# [Added By GCR]' >> ~/.bash_profile
            echo '[ -f $HOME/zsh/bin/zsh ] && exec $HOME/zsh/bin/zsh -l' >> ~/.bash_profile
        fi
        cd $HOME/GCR
    fi
elif [ "${install_gcr_os}" = 5 ]; then
    # nscc
    if [ ! -e "$HOME/zsh/bin/zsh" ]; then
        mkdir -p $HOME/zsh && tar -xf zsh/zsh-5.9.tar.xz -C $HOME
        cd $HOME/zsh && ./configure --prefix=$HOME/zsh
        make && make install
        echo '# [Added By GCR]' >> ~/.bash_profile
        echo 'export FPATH=$HOME/zsh/share/zsh/5.9/functions:$HOME/zsh/share/zsh/site-functions:/usr/local/share/zsh/site-functions:$HOME/.cache/oh-my-zsh/completions:$HOME/.oh-my-zsh/completions:$HOME/.oh-my-zsh/functions:$HOME/.oh-my-zsh/plugins/git:$HOME/.oh-my-zsh/plugins/extract:$HOME/.oh-my-zsh/plugins/autojump:$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting:$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions:$HOME/.oh-my-zsh/custom/plugins/zsh-myincr:$HOME/.oh-my-zsh/plugins/aliases:$HOME/.oh-my-zsh/plugins/docker:$HOME/.oh-my-zsh/plugins/docker-compos:$HOME/.oh-my-zsh/plugins/gitignore:$HOME/.oh-my-zsh/plugins/sud:$FPATH' >> ~/.bash_profile
        echo 'export PATH=$HOME/zsh/bin:$PATH' >> ~/.bash_profile
        echo 'export SHELL=$HOME/zsh/bin/zsh' >> ~/.bash_profile
        echo '[ -f $HOME/zsh/bin/zsh ] && exec $HOME/zsh/bin/zsh -l' >> ~/.bash_profile
        echo '# [Added By GCR]' >> ~/.bash_profile
        cd $HOME/GCR
    fi
fi

print_text "cyan" "Start generating zshrc file..." "false"
printf "\n"
# add to .zshrc file
if [ -e "$HOME/.zshrc" ]; then
    print_text "green" "~/.zshrc already exists:" "false"
    printf "\n"
    print_text "green" "========================" "false"
    printf "\n"
    cat ~/.zshrc
    print_text "green" "========================" "false"
    printf "\n"
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
echo 'source ~/.ohmyshell' >> ~/.zshrc
echo '# [ Added By GCR ]' >> ~/.zshrc

# specfic for nscc
if [ "${install_gcr_os}" = 5 ]; then
    echo 'module ()
{
    eval `/opt/cray/pe/modules/3.2.11.6/bin/modulecmd bash $*`
}' >> ~/.zshrc
fi

# Sucess message
print_table_text "Successful! Please restart the shell!!" "yes" "yellow" "red" $(tput cols)

cd
rm -rf $HOME/GCR
