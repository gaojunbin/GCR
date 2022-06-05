# sync to mac
rsync .ohmyshell ~/
rsync .ohmyzsh ~/
rsync .p9k.zsh ~/

# sync .ohmyshell to remote
echo 'whether to sync .ohmyshell to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    # sync to THU Host
    rsync .ohmyshell img16:~/
    rsync .ohmyshell img17:~/
    rsync .ohmyshell img18:~/
    rsync .ohmyshell img72:~/
    rsync .ohmyshell img73:~/
    rsync .ohmyshell img74:~/
    rsync .ohmyshell img75:~/
    rsync .ohmyshell img77:~/
    rsync .ohmyshell img81:~/
    rsync .ohmyshell img82:~/
    # sync to HUST Host
    rsync .ohmyshell sys2:~/
    rsync .ohmyshell sys3:~/
    rsync .ohmyshell sys4:~/
    rsync .ohmyshell sys5:~/
fi

# sync .ohmyzsh to remote
echo 'whether to sync .ohmyzsh to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    rsync .ohmyzsh img16:~/
    rsync .ohmyzsh img17:~/
    rsync .ohmyzsh img18:~/
    rsync .ohmyzsh img72:~/
    rsync .ohmyzsh img73:~/
    rsync .ohmyzsh img74:~/
    rsync .ohmyzsh img75:~/
    rsync .ohmyzsh img77:~/
    rsync .ohmyzsh img81:~/
    rsync .ohmyzsh img82:~/
    rsync .ohmyzsh sys2:~/
    rsync .ohmyzsh sys3:~/
    rsync .ohmyzsh sys4:~/
    rsync .ohmyzsh sys5:~/
fi

# sync .p9k.zsh to remote
echo 'whether to sync .p9k.zsh to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    rsync .p9k.zsh img16:~/
    rsync .p9k.zsh img17:~/
    rsync .p9k.zsh img18:~/
    rsync .p9k.zsh img72:~/
    rsync .p9k.zsh img73:~/
    rsync .p9k.zsh img74:~/
    rsync .p9k.zsh img75:~/
    rsync .p9k.zsh img77:~/
    rsync .p9k.zsh img81:~/
    rsync .p9k.zsh img82:~/
    rsync .p9k.zsh sys2:~/
    rsync .p9k.zsh sys3:~/
    rsync .p9k.zsh sys4:~/
    rsync .p9k.zsh sys5:~/
fi