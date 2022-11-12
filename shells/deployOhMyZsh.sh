#!/bin/bash
apt --help > /dev/null
if [ $? -ne 0 ];then
    PACKAGE_CMD=yum
else
    PACKAGE_CMD=apt
fi
cd ~
if [ ! \( -a "/etc/sudoers.d" \) ]
then 
  $PACKET_CMD update && $PACKET_CMD install -y sudo
fi

echo "正在更新$PACKET_CMD包源"
sudo $PACKET_CMD update

echo "正在安装zsh,wget,git"
sudo $PACKET_CMD install zsh wget git -y

echo "正在改变登陆shell为zsh,下次登陆将以zsh登陆"
sudo chsh -s /bin/zsh
sudo usermod -s /bin/zsh $USER 

echo "正在安装oh-my-zsh"
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh

echo "正在安装zsh-syntax-highlighting,zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "正在拉取.zshrc文件并应用"
wget https://gitee.com/guo-fuwei/library/releases/download/v0.2/zshrc
sudo mv ~/.zshrc ~/.zshrc_bak
sudo mv ./zshrc ~/.zshrc
zsh
source ~/.zshrc
