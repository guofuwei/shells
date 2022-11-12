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
  $PACKAGE_CMD update && $PACKAGE_CMD install -y sudo
fi
sudo $PACKAGE_CMD update && sudo $PACKAGE_CMD install -y wget git
echo "正在拉取项目"
git clone https://gitee.com/guo-fuwei/library.git
cd library
if [ -z $1 ] && [ ! \( -a "config.yaml" \) ]
then
  echo "未输入clash config.yaml链接,程序将退出"
  exit
fi

echo -n "是否需要更换阿里源镜像$PACKAGE_CMD(输入y/Y确定，输入其他跳过):"
read choice;
if [[ $choice = "y" || $choice = "Y" ]]
then
  if [ -a "/etc/$PACKAGE_CMD/sources.list" ]
  then
    echo "正在备份$PACKAGE_CMD源文件"
    sudo cp /etc/$PACKAGE_CMD/sources.list /etc/$PACKAGE_CMD/source.list.bak
    echo "正在更换阿里源国内镜像"
    sudo rm /etc/$PACKAGE_CMD/sources.list
  fi
  sudo mv sources.list /etc/$PACKAGE_CMD/sources.list
  sudo $PACKAGE_CMD update 
fi


# wget https://gitee.com/guo-fuwei/library/blob/master/clash-linux-amd64-v1.11.8.gz 
echo "正在进行文件准备"
if [ -a "clash" ]
then
  chmod u+x clash
else
  gunzip clash-linux-amd64-v1.11.8.gz 
  mv clash-linux-amd64-v1.11.8 clash
  chmod u+x clash
fi
# wget https://gitee.com/guo-fuwei/library/blob/master/Country.mmdb
if [[ -a "config.yaml" && -n $1 ]]
then
  echo -n "已存在config.yaml文件，是否进行覆盖(输入y/Y确定，输入其他跳过):"
  read choice
  if [[ $choice = "y" || $choice = "Y" ]]
  then
    wget -O config.yaml $1 
  fi
elif [ ! \( -a "config.yaml" \) ] && [ -n $1 ]
then
  wget -O config.yaml $1
fi


if which init && [ -a "/lib/systemd/systemd" ]
then
  echo "您使用的是systemctl init方法"
  echo "正在移动clash必要文件到系统目录"
  sudo mkdir /etc/clash
  sudo cp clash /usr/local/bin 
  sudo cp config.yaml /etc/clash/ 
  sudo cp Country.mmdb /etc/clash/

  echo "正在创建clash.service"
  sudo cp clash.service /etc/systemd/system/clash.service
  echo "设置clash开机自启动"
  sudo systemctl enable clash 
  echo "启动clash"
  sudo systemctl start clash

  echo "正在为您设置http_proxy,https_proxy代理"
  if [ $SHELL = "/bin/bash" ]
  then 
    echo "export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890" >> ~/.bashrc
    source ~/.bashrc
  elif [ $SHELL = "/bin/zsh" ]
  then 
    echo "export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890" >> ~/.zshrc
    source ~/.zshrc
  fi
else 
  echo "抱歉，暂不支持其他的init方法，将在前台启动clash"
  ./clash -d .
fi



