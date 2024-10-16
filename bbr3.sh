#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 更新软件包列表
sudo apt update

# 安装必备工具
sudo apt install -y curl wget gnupg2 ca-certificates lsb-release

# 导入 XanMod GPG 密钥
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg

# 添加 XanMod 软件源
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

# 更新软件包列表并安装 XanMod 内核
sudo apt update && sudo apt install -y linux-xanmod-x64v3

# 判断内核是否安装成功
if [ $? -eq 0 ]; then
    echo -e "${GREEN}内核安装成功，请重启系统以应用新内核。${NC}"
else
    echo -e "${RED}内核安装失败，请检查错误信息。${NC}"
    exit 1
fi

# 提示是否立即重启
echo -e "${GREEN}是否现在重启？(y/n)${NC}"
read reboot_now
if [ "$reboot_now" == "y" ]; then
    sudo reboot
fi

# 检查新内核安装完成后，启用BBRv3
read -p "是否已经重启并运行新内核？(y/n)" rebooted

if [ "$rebooted" == "y" ]; then
    # 启用BBRv3
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # 验证BBRv3是否已启用
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo -e "${GREEN}BBRv3 已启用！${NC}"
    else
        echo -e "${RED}BBRv3 启用失败，请检查内核是否正确安装或配置。${NC}"
    fi

else
    echo -e "${RED}请重启后再次运行该脚本以启用 BBRv3。${NC}"
fi

