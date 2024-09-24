#!/usr/bin/env bash
# Blog: https://www.moerats.com/

# 定义颜色
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# 检查是否以root权限运行
root_need() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error: This script must be run as root!${Font}"
        exit 1
    fi
}

# 检查是否为OpenVZ虚拟化
ovz_no() {
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}Error: Your VPS is based on OpenVZ, which does not support swap!${Font}"
        exit 1
    fi
}

# 添加swap
add_swap() {
    echo -e "${Green}请输入需要添加的swap大小，单位为MB，建议为内存的2倍。${Font}"
    while true; do
        read -p "请输入swap大小 (MB): " swapsize
        # 检查用户输入是否为正整数
        if [[ $swapsize =~ ^[0-9]+$ ]] && [[ $swapsize -gt 0 ]]; then
            break
        else
            echo -e "${Red}输入无效，请输入正整数。${Font}"
        fi
    done

    # 检查是否已经存在swapfile
    if ! grep -q "swapfile" /etc/fstab; then
        echo -e "${Green}未发现swapfile，正在创建swapfile...${Font}"
        fallocate -l ${swapsize}M /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=${swapsize}
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        echo -e "${Green}swap创建成功，详细信息如下：${Font}"
        cat /proc/swaps
        grep Swap /proc/meminfo
    else
        echo -e "${Red}swapfile已存在，无法再次创建！请先删除现有swap。${Font}"
    fi
}

# 删除swap
del_swap() {
    if grep -q "swapfile" /etc/fstab; then
        echo -e "${Green}发现swapfile，正在移除...${Font}"
        sed -i '/swapfile/d' /etc/fstab
        swapoff /swapfile
        rm -f /swapfile
        echo "3" > /proc/sys/vm/drop_caches
        echo -e "${Green}swap已成功删除！${Font}"
    else
        echo -e "${Red}未发现swapfile，无法删除。${Font}"
    fi
}

# 菜单界面
main() {
    root_need
    ovz_no
    clear
    echo -e "———————————————————————————————————————"
    echo -e "${Green}Linux VPS 一键添加/删除 swap 脚本${Font}"
    echo -e "${Green}1. 添加swap${Font}"
    echo -e "${Green}2. 删除swap${Font}"
    echo -e "———————————————————————————————————————"
    read -p "请输入数字 [1-2]: " num
    case "$num" in
        1)
            add_swap
            ;;
        2)
            del_swap
            ;;
        *)
            echo -e "${Red}请输入正确的数字 [1-2]${Font}"
            sleep 2
            main
            ;;
    esac
}

# 运行脚本主函数
main
