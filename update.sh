# sync to mac
rsync .ohmyshell ~/
rsync .ohmytool ~/
rsync .ohmyzsh ~/
rsync .p9k.zsh ~/
# rsync .vimrc ~/

# sync .ohmyshell to remote
echo 'whether to sync .ohmyshell to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    # sync to Homeweb
    rsync .ohmyshell homeweb-huawei:~/
    rsync .ohmyshell homeweb-tencent:~/
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
    # sync to NUS Host
    rsync .ohmyshell liulab:~/
fi

# sync .ohmytool to remote
echo 'whether to sync .ohmytool to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    rsync .ohmytool homeweb-huawei:~/
    rsync .ohmytool homeweb-tencent:~/
    rsync .ohmytool img16:~/
    rsync .ohmytool img17:~/
    rsync .ohmytool img18:~/
    rsync .ohmytool img72:~/
    rsync .ohmytool img73:~/
    rsync .ohmytool img74:~/
    rsync .ohmytool img75:~/
    rsync .ohmytool img77:~/
    rsync .ohmytool img81:~/
    rsync .ohmytool img82:~/
    rsync .ohmytool sys2:~/
    rsync .ohmytool sys3:~/
    rsync .ohmytool sys4:~/
    rsync .ohmytool sys5:~/
fi

# sync .ohmyzsh to remote
echo 'whether to sync .ohmyzsh to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    rsync .ohmyzsh homeweb-huawei:~/
    rsync .ohmyzsh homeweb-tencent:~/
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
    rsync .p9k.zsh homeweb-huawei:~/
    rsync .p9k.zsh homeweb-tencent:~/
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

# sync .vimrc to remote
echo 'whether to sync .vimrc to remote? ([y]/n)? \c'
read yon
if [ "${yon}" = "y" ];then
    rsync .vimrc homeweb-huawei:~/
    rsync .vimrc homeweb-tencent:~/
    rsync .vimrc img16:~/
    rsync .vimrc img17:~/
    rsync .vimrc img18:~/
    rsync .vimrc img72:~/
    rsync .vimrc img73:~/
    rsync .vimrc img74:~/
    rsync .vimrc img75:~/
    rsync .vimrc img77:~/
    rsync .vimrc img81:~/
    rsync .vimrc img82:~/
    rsync .vimrc sys2:~/
    rsync .vimrc sys3:~/
    rsync .vimrc sys4:~/
    rsync .vimrc sys5:~/
fi