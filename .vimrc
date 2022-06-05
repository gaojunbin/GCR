"开启高亮
syntax on

"设置 tab 宽度为 4
set ts=4
set expandtab
set autoindent

"开启新行时使用智能自动缩进
set smartindent

"显示状态栏 (默认值为 1, 无法显示状态栏)
"set laststatus=2

"设置在状态行显示的信息
set statusline=\ %<%F[%1*%M%*%n%R%H]%=\ %y\ %0(%{&fileformat}\ %{&encoding}\ Ln\ %l,\ Col\ %c/%L%)

"设定配色方案
"colorscheme evening

"显示行号
set number

" 突出显示当前行
"set cursorline

" 打开状态栏标尺
"set ruler

" 去掉输入错误的提示声音
set noeb

" 代码补全
set completeopt=preview,menu

" 禁止生成临时文件
set noswapfile

" 不需要备份
set nobackup

