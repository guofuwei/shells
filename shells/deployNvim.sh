#!/bin/bash
cd ~
if [ ! \( -a "/etc/sudoers.d" \) ]
then 
  apt update && apt install sudo -y
fi

echo "安装nodejs,npm,ctags,python"
sudo apt install -y  npm python3 pip wget curl clangd
sudo npm install n -g
export NODE_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
n lts
pip install pynvim
sudo apt install astyle clang-format ctags -y 

echo "添加nvim apt包源"
sudo apt update  && sudo apt install -y software-properties-common
sudo add-apt-repository ppa:neovim-ppa/stable

echo "安装neovim"
sudo apt update && sudo apt install neovim wget -y

echo "安装vim-plug"
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "拉取init.vim配置文件,并移动到~/.config/nvim/"
wget https://gitee.com/guo-fuwei/library/releases/download/v0.2/init.vim
mkdir -p ~/.config/nvim
mv init.vim ~/.config/nvim/init.vim

echo "Done!"
