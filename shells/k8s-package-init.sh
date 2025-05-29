#!/bin/bash

# Kubernetes 安装配置脚本
# 适用于 Ubuntu/Debian 系统

set -e  # 遇到错误时退出

echo "开始 Kubernetes 集群配置..."

# ================================
# 1. 关闭交换分区
# ================================
echo "正在关闭交换分区..."
sudo swapoff -a

echo "请手动编辑 /etc/fstab 文件，注释掉交换分区相关行以永久禁用交换分区"
echo "按任意键继续..."
read -n 1

# ================================
# 2. 设置版本变量
# ================================
echo "设置 Kubernetes 和 CRI-O 版本..."
export KUBERNETES_VERSION="v1.33"  # 可根据需要修改版本
export CRIO_VERSION="v1.33"        # 可根据需要修改版本

# echo "设置环境代理"
# export http_proxy="http://192.168.1.1:7897"
# export https_proxy="http://192.168.1.1:7897"
# 取消代理设置
unset http_proxy
unset https_proxy
unset all_proxy

echo "Kubernetes 版本: $KUBERNETES_VERSION"
echo "CRI-O 版本: $CRIO_VERSION"

# ================================
# 3. 安装依赖包
# ================================
echo "正在安装依赖包..."
sudo apt-get update
sudo apt-get install -y software-properties-common curl gpg

# ================================
# 4. 添加 Kubernetes 仓库
# ================================
echo "正在添加 Kubernetes 仓库..."

# 创建 keyrings 目录（如果不存在）
sudo mkdir -p /etc/apt/keyrings

# 添加 Kubernetes GPG 密钥
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 添加 Kubernetes 仓库源
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

# ================================
# 5. 添加 CRI-O 仓库
# ================================
echo "正在添加 CRI-O 仓库..."

# 添加 CRI-O GPG 密钥
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

# 添加 CRI-O 仓库源
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/cri-o.list

# ================================
# 6. 安装 Kubernetes 组件和 CRI-O
# ================================
echo "正在安装 Kubernetes 组件和 CRI-O..."
sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl

# 锁定版本，防止意外升级
echo "锁定 Kubernetes 组件版本..."
sudo apt-mark hold kubelet kubeadm kubectl

# ================================
# 7. 启动 CRI-O 服务
# ================================
echo "正在启动 CRI-O 服务..."
sudo systemctl start crio.service
sudo systemctl enable crio.service

# ================================
# 8. 配置网络模块
# ================================
echo "正在配置网络模块..."

# 启用 br_netfilter 模块
sudo modprobe br_netfilter

# 持久化 br_netfilter 模块配置
echo "配置 br_netfilter 模块持久化..."
if [ -f /etc/modules-load.d/br_netfilter.conf ]; then
    echo "删除现有的 br_netfilter.conf 文件..."
    sudo rm -f /etc/modules-load.d/br_netfilter.conf
fi

echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

# 更新 initramfs
echo "更新 initramfs..."
sudo update-initramfs -u

# ================================
# 9. 配置内核参数
# ================================
echo "正在配置内核参数..."

# 删除现有配置文件（如果存在）
if [ -f /etc/sysctl.d/99-kubernetes-cri.conf ]; then
    echo "删除现有的内核参数配置文件..."
    sudo rm -f /etc/sysctl.d/99-kubernetes-cri.conf
fi

# 创建新的内核参数配置
echo "创建内核参数配置文件..."
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# 应用内核参数
echo "应用内核参数配置..."
sudo sysctl --system

# ================================
# 10. 完成提示
# ================================
echo ""
echo "=========================================="
echo "Kubernetes 基础配置完成！"
echo "=========================================="
echo ""
echo "接下来的步骤："
echo "1. 如果这是主节点，运行: sudo kubeadm init"
echo "2. 如果这是工作节点，运行: sudo kubeadm join <master-ip>:<port> --token <token> --discovery-token-ca-cert-hash <hash>"
echo "3. 配置 kubectl（仅主节点需要）:"
echo "   mkdir -p \$HOME/.kube"
echo "   sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo "   sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo "4. 安装网络插件（如 Calico、Flannel 等）"
echo ""
echo "注意：请确保已经手动编辑 /etc/fstab 文件禁用交换分区！"
