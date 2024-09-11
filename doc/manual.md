[TOC]

<h1 style="text-align: center;">📖 用户指南</h1>



---

## 🌟 推荐必装



####  🔥 **Tssh & trzsz** - ssh登陆和终端文件传输

💡 **功能描述**：

trzsz tssh 是重塑终端ssh登陆方式和本地-服务器文件传输方式的工具，最终目的是配合原生ssh工具实现更优雅便捷的服务器登陆，同时赋予终端文件可视化传输的功能。

•	**服务器登陆**：tssh即可列出所有可用服务器详情，可交互式搜索、选择需要连接的服务器。

•	**文件传输**：支持在终端的文件/文件夹传输：1. 本地到服务器 - 拖拽（所见即所得）； 2. 服务器到本地  - download 文件/文件夹

🔗 **安装命令**：

```bash
# 本地电脑（支持MacOS, Ubuntu, Win，更多详情请参考https://github.com/trzsz/trzsz-ssh 自行安装)
install_tssh

# 远程服务器
install_trzsz
```

🔗 **使用方式**：

```bash
# 连接服务器
tssh

# 上传文件/文件夹
upload # 或者直接拖拽

# 下载文件/文件夹
download 文件1 文件夹2
```

⚠️ 说明：

•	tssh支持主流操作系统(MacOS, Ubuntu, Win)，但是在无可视化界面的虚拟机、win子系统等情况下可能无法调用交互式界面。

•	tssh在兼容原生ssh的同时支持丰富的自定义配置方案，大大提升效率和体验。可参阅[官网](https://github.com/trzsz/trzsz-ssh)阅读详细配置规则。这里提供一个模版供参考(兼容原生ssh) `~/.ssh/config`：

```yaml
# 所有服务器都转发端口59863到本地（供code命令使用，另一个非常推荐的功能）
# 所有服务器tssh支持拖拽文件上传
Host *
    RemoteForward 59863 127.0.0.1:52698
    #!! EnableDragFile Yes

# 所有nscc开头的服务器都分类到NUS标签和NSCC标签下
Host nscc*
    #!! GroupLabels NUS
    #!! GroupLabels NSCC

# 登陆节点信息，隐藏该服务器
Host nscc
    HostName aspire2a.nus.edu.sg
    User username
    ServerAliveInterval 60
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/nus/nscc
    #!! HideHost yes

# 真正的登陆节点（指定登陆到nus01节点）
Host nscc-nus01  
    HostName asp2a-login-nus01
    User username
    IdentityFile ~/.ssh/nus/nscc
    ProxyJump nscc
```



#### 🔥 **Autojump** - 快速目录跳转

💡 **功能描述**：

Autojump 是一款智能目录跳转工具，可以根据你访问过的目录频率来快速定位。它通过学习你的操作习惯，让你只需输入目录的一部分即可跳转至常用的路径，大幅提升工作效率。

•	**自动学习路径**：访问次数越多的目录，跳转越快。

•	**极简命令**：j + 你想去的目录名即可，目录名不需要很准确，支持模糊匹配，也不需要一步步寻找路径。

🔗 **安装命令**：
```bash
install_autojump
```

🔗 **使用方式**：

```bash
j 你想去的地方的任意模糊关键词
```



#### 🔥 **Saferm** - 安全删除

💡 **功能描述**：

saferm 是一款安全删除工具，取代了原生的rm，无需关注删除的是文件还是文件夹，del可以统统删除，并且会自动放入指定的回收站中，轻松找回，让你删除文件变得更方便与安全。

•	**操作方便**：无论是文件还是文件夹，只需要一个命令即可统统删除。

•	**安全好找回**：del删除会默认放入指定的回收站，你可以在回收站中轻松找回。有多个同名文件时，会自动加上删除时间后缀，所有信息都安全无虞！

•	**智能空间管理**：为了防止回收站占用你太大的磁盘空间，del 删除时会检查文件大小，删除文件超过10G时，会提示是否放入回收站，你也可以使用delf来进行手动永久删除（delf等同于原生rm，但是同样无需顾及是文件还是文件夹）

•	**轻松清空回收站**：empty_trash一键清空回收站，支持两种模式：一键清空回收站全部内容 / 清空删除超过30天的文件。

🔗 **安装命令**：

```bash
install_safe_rm

# 可选（建议）：设置回收站的路径(建议存放到.zshrc中)
export SAFE_RM_TRASH=$HOME/.Trash
```

🔗 **使用方式**：

```bash
# 删除文件/文件夹（放入回收站）
del 文件名/文件夹名
# 删除文件/文件夹（不放入回收站）
delf 文件名/文件夹名
# 清空回收站
empty_trash
```



#### 🔥 **Code** - 终端编辑器

💡 **功能描述**：

code 是一款基于rmate的工具，可以让你在终端更符合直觉地编辑代码/文件，从此弃用VI/VIM。适用于当你想轻度编辑文件但又不想使用vim的场景。

•	**自动识别本地和服务器**：code会自动识别当前终端是在本地还是远程并启用相应的逻辑让你编辑文件。

•	**本地文件编辑**：code会直接使用 sublime text/ vs code 打开当前文件/文件夹，编辑完成后保存并关闭即可。无需在编辑器内搜寻并打开相应的文件，也无需在终端内使用vim编辑。

•	**服务器文件编辑**：code会自动同步远程文件到本地临时存储，并使用本地 sublime text/ vs code 打开该文件，编辑完成后保存并关闭即可，code会自动同步至服务器。整个过程的同步无需用户任何操作，就跟编辑本地文件一样的流程。

🔗 **安装命令**：

```bash
# 服务器端
install_discard_vim

# 按照服务器端的提示修改本地配置，主要包括：
# 1. vscode / sublime 插件 （用来支持rmate）
# 2. tssh config端口转发
```

🔗 **使用方式**：

```bash
code 文件名
```



---

## 📋 使用指南

### 1. 初次使用
   - 安装GCR后，建议本地安装tssh并完善ssh config配置以获取更好的体验
   - 阅读推荐必装，并安装你感兴趣的功能（强烈建议都装）
   - 整理原先shell的环境配置，将需要保留的环境变量整理到一个新的文件中，并在`~/.zshrc`中source该文件

### 2. GCR使用逻辑

GCR基于oh-my-zsh实现，定制化了ohmyzsh的部分功能，包括终端显示主题，样式，激活的插件等，默认开启自动提示和补全（修复了原版存在的bug）此外，核心功能主要包括GCR版本管理，ohmyshell, ohmytool。



整体功能函数遵循一二三分级标准。（随着版本更新，可能支持更多一级函数，但是逐级调用的逻辑会继续传承）

一级函数包括ohmyshell，ohmytool，一级函数可以访问所有二级函数；（⚠️ohmytool下暂未实现二级函数）

二级函数包括各一级函数下属的各个功能模块函数，比如针对anaconda，pip等模块的个性化函数；二级函数可以访问所有三级函数；

三级函数包括各个模块下的具体功能函数，执行某个具体功能；



用户只需记忆一级函数，即可访问所有GCR功能函数！

### 3. GCR 函数功能总览

| 一级函数  |                 功能描述                 |
| :-------: | :--------------------------------------: |
| ohmyshell | GCR版本管理，shell常见原生操作的增强工具 |
| ohmytool  |          一键安装各类工具/软件           |

|   二级函数   |            功能            | 所属一级函数 |
| :----------: | :------------------------: | :----------: |
|   myupdate   |        更新GCR版本         |  ohmyshell   |
|    mytool    |     一些shell常用工具      |  ohmyshell   |
|    mypip     |    针对python pip的扩展    |  ohmyshell   |
|    myenv     | 针对anaconda管理环境的扩展 |  ohmyshell   |
|    mygpu     |   针对GPU用户的常用命令    |  ohmyshell   |
| mypermission |  管理用户密码，文件权限等  |  ohmyshell   |
|    mygit     |     针对git操作的扩展      |  ohmyshell   |

|    二级函数     |                             功能                             | 所属一级函数 |
| :-------------: | :----------------------------------------------------------: | :----------: |
| install_public  |                   一键安装常用工具，通用型                   |   ohmytool   |
| install_private | 【不可用】一键安装常用工具，项目开发之初不打算开源，因此部分功能涉及隐私，此部分不可用，后续会移出GCR本体并做成插件导入，同时支持用户导入自定义插件库 |   ohmytool   |



---

## 📚 附录（全部功能）

| 一级函数  |   二级函数   |           三级函数            |            功能            |  参数  |                             说明                             |
| :-------: | :----------: | :---------------------------: | :------------------------: | :----: | :----------------------------------------------------------: |
| ohmyshell |              |                               |                            |        |                                                              |
|           |   myupdate   |           myupdate            |        更新GCR版本         | 不需要 |                                                              |
|           |              |                               |                            |        |                                                              |
|           |    mytool    |              jp               |    打开jupyter notebook    | 不需要 |                 需要安装jupyter lab/notebook                 |
|           |              |            listen             |        ssh 端口转发        | 不需要 |                       支持多种转发模式                       |
|           |              |            pathadd            | 添加一个环境变量到shell中  | 不需要 |                                                              |
|           |              |           condainit           |  添加conda初始化到shell中  | 不需要 |         等同于安装anaconda时候默认添加到shell的部分          |
|           |              |              sz               |   查看文件/文件夹的大小    | 不需要 |   支持查看特定文件/文件夹大小，文件数量或者服务器硬盘空间    |
|           |              |          listen_vpn           |   控制服务器端clash VPN    | 不需要 |                    需要服务器端开启clash                     |
|           |              |     download_googledrive      |   从Google drive下载文件   | 不需要 |                        需要安装gdown                         |
|           |              |            vpstest            |       测试服务器参数       | 不需要 |                       测试vps常用工具                        |
|           |              |                               |                            |        |                                                              |
|           |    mypip     |            pipset             |       设置pip安装源        | 不需要 |                    可选项: 清华/阿里/腾讯                    |
|           |              |            pipbase            |      pip安装常用的包       | 不需要 | 可选项（推荐全部安装）：'pygments' 'gpustat' 'jupyterlab' 'tensorboard' 'woaigpu' 'gdown' 'shell-gpt' |
|           |              |             pipl              |      pip查看安装的包       | 不需要 |                                                              |
|           |              |             pipi              |          pip安装           |  可选  |          若不带参数默认运行pip install -r req*.txt           |
|           |              |             pipu              |          pip卸载           |  需要  |                                                              |
|           |              |                               |                            |        |                                                              |
|           |    myenv     |              env              |       激活conda环境        |  可选  | 不带参数将展示可激活环境并等待选择，带参数则直接激活目标环境 |
|           |              |             lenv              |    显示已安装conda环境     | 不需要 |                                                              |
|           |              |             cenv              |     创建新的conda环境      | 不需要 |                                                              |
|           |              |             denv              |  删除现有的某个conda环境   | 不需要 |                                                              |
|           |              |                               |                            |        |                                                              |
|           |    mygpu     |              gpu              | 实时查看GPU的用户使用情况  | 不需要 |                      需要pip安装gpustat                      |
|           |              |            nvidia             |   实时查看GPU的使用情况    | 不需要 |                      实时查看nvidia-smi                      |
|           |              |              pid              |  查看所有GPU运行任务的pid  | 不需要 |                       方便杀gpu死进程                        |
|           |              |             gpus              |    显示指定显卡号的命令    | 不需要 |                                                              |
|           |              |                               |                            |        |                                                              |
|           | mypermission |            mychmod            |         魔改chmod          | 不需要 |                                                              |
|           |              |            mychown            |         魔改chown          | 不需要 |                                                              |
|           |              |            passwd             |        修改账号密码        | 不需要 |                                                              |
|           |              |                               |                            |        |                                                              |
|           |    mygit     |             gita              |          git add           |  需要  |                                                              |
|           |              |             gitaa             |         git add .          | 不需要 |                                                              |
|           |              |             gitb              |         git branch         | 不需要 |                                                              |
|           |              |             gitc              |       魔改git commit       | 不需要 |                                                              |
|           |              |             gitl              |          git log           | 不需要 |                                                              |
|           |              |              gc               |         git clone          | 不需要 |                                                              |
|           |              |             gitst             |         git status         | 不需要 |                                                              |
|           |              |                               |                            |        |                                                              |
|           |    (其他)    |              sc               |    source ${shell_file}    | 不需要 |                        刷新shell环境                         |
|           |              |               l               |          joshuto           | 不需要 |               如果安装joshuto，l被joshuto取代                |
|           |              |              cl               |           clear            | 不需要 |                                                              |
|           |              |             pcat              |       pygmentize -g        |  需要  |                                                              |
|           |              |              tb               |        tensorboard         | 不需要 |                                                              |
|           |              |        download/upload        |    下载/上传文件/文件夹    |  可选  |                          依赖trzsz                           |
|           |              |           startvpn            |         终端走代理         | 不需要 |                        需要开启clash                         |
|           |              |            stopvpn            |        终端不走代理        | 不需要 |                                                              |
|           |              |           dockeradd           |   加入用户到docker用户组   | 不需要 |                         需要root权限                         |
|           |              |                               |                            |        |                                                              |
| ohmytool  |              |                               |                            |        |                                                              |
|           |    (暂无)    |         new_vps_help          |             -              |        |                                                              |
|           |              |          install_vpn          |             -              |        |                                                              |
|           |              |          install_xui          |             -              |        |                                                              |
|           |              |        install_docker         |         安装docker         |        |                                                              |
|           |              |         install_trzsz         |   支持终端文件上传/下载    |        |                           推荐！！                           |
|           |              |         install_tssh          |        替换原生ssh         |        |                           推荐！！                           |
|           |              |       install_spacevim        |        安装超级vim         |        |                 不推荐，推荐使用code取代vim                  |
|           |              | install_server-administration |    服务器管理员常用工具    |        |                                                              |
|           |              |      install_nginxproxy       |        安装npm反代         |        |                                                              |
|           |              |        install_homeweb        |             -              |        |                                                              |
|           |              |        install_newtab         |             -              |        |                                                              |
|           |              |         install_deepl         |             -              |        |                                                              |
|           |              |       install_cloudreve       |             -              |        |                                                              |
|           |              |       install_overleaf        |       overleaf开源版       |        |                                                              |
|           |              |     install_serverstatus      |       服务器状态监控       |        |                                                              |
|           |              |          install_frp          |        frp内网穿透         |        |                                                              |
|           |              |        install_chatgpt        |       chatgpt网页版        |        |                                                              |
|           |              |      install_webmonitor       |        网站监控爬虫        |        |                                                              |
|           |              |       install_vncdocker       |      网页版vnc可视化       |        |                                                              |
|           |              |      install_qbittorrent      |             -              |        |                                                              |
|           |              |       install_jellyfin        |       jellyfin影视库       |        |                                                              |
|           |              |         install_image         |          兰空图床          |        |                                                              |
|           |              |       install_samtools        |           #TODO            |        |                                                              |
|           |              |       install_PBShelper       |        PBS系统助手         |        |                     推荐！NSCC/HPC好帮手                     |
|           |              |     install_htop_wo_sudo      | 无root权限的服务器安装htop |        |                                                              |
|           |              |       install_autojump        |          自动跳转          |        |                           推荐！！                           |
|           |              |          install_fzf          |    terminal命令模糊搜索    |        |                                                              |
|           |              |       install_copypaste       |             -              |        |                                                              |
|           |              |        install_safe_rm        |          安全删除          |        |                           推荐！！                           |
|           |              |      install_discard_vim      |     丢弃vim，拥抱code      |        |                           推荐！！                           |
|           |              |        install_joshuto        |     支持l查看文件系统      |        |                                                              |

