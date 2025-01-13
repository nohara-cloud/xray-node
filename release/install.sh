#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/nohara-node.service ]]; then
        return 2
    fi
    temp=$(systemctl status nohara-node | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_nohara_node() {
    if [[ -e /usr/local/bin/nohara-node ]]; then
        rm /usr/local/bin/nohara-node
    fi

    mkdir -p /etc/nohara-node/
	cd /etc/nohara-node/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/nohara-cloud/nohara-node/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 Nohara Node 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 Nohara Node 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 Nohara Node 最新版本：${last_version}，开始安装"
        echo -e "下载地址: https://github.com/nohara-cloud/nohara-node/releases/download/${last_version}/nohara-node-linux-${arch}.zip"
        wget -q -N --no-check-certificate -O /etc/nohara-node/nohara-node-linux.zip https://github.com/nohara-cloud/nohara-node/releases/download/${last_version}/nohara-node-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 Nohara Node 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        if [[ $1 == v* ]]; then
            last_version=$1
    else
        last_version="v"$1
    fi
        url="https://github.com/nohara-cloud/nohara-node/releases/download/${last_version}/nohara-node-linux-${arch}.zip"
        echo -e "开始安装 Nohara Node ${last_version}"
        echo -e "下载地址: ${url}"
        wget -q -N --no-check-certificate -O /etc/nohara-node/nohara-node-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 Nohara Node ${last_version} 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    unzip nohara-node-linux.zip -d /tmp/nohara-node
    rm nohara-node-linux.zip -f
    # Setup binary
    chmod +x /tmp/nohara-node/nohara-node
    mv /tmp/nohara-node/nohara-node /usr/local/bin/nohara-node
    # Setup service
    rm /etc/systemd/system/nohara-node.service -f
    file="https://github.com/nohara-cloud/nohara-node/raw/master/release/nohara-node.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/nohara-node.service ${file}
    systemctl daemon-reload
    systemctl stop nohara-node
    systemctl enable nohara-node
    echo -e "${green}Nohara Node ${last_version}${plain} 安装完成，已设置开机自启"
    # Setup geoip.dat and geosite.dat
    cp /tmp/nohara-node/geoip.dat /etc/nohara-node/
    cp /tmp/nohara-node/geosite.dat /etc/nohara-node/ 

    # Won't override user exist config file
    if [[ ! -f /etc/nohara-node/config.yml ]]; then
        cp config.yml /etc/nohara-node/
        echo -e ""
        echo -e "全新安装，请先参看教程：https://nohara.tech，配置必要的内容"
    else
        systemctl start nohara-node
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}Nohara Node 重启成功${plain}"
        else
            echo -e "${red}Nohara Node 可能启动失败，请稍后使用 nohara-node log 查看日志信息，若无法启动，则可能更改了配置格式，请前往 wiki 查看：https://github.com/nohara-cloud/nohara-node/wiki${plain}"
        fi
    fi
    if [[ ! -f /etc/nohara-node/dns.json ]]; then
        cp /tmp/nohara-node/dns.json /etc/nohara-node/
    fi
    if [[ ! -f /etc/nohara-node/route.json ]]; then
        cp /tmp/nohara-node/route.json /etc/nohara-node/
    fi
    if [[ ! -f /etc/nohara-node/custom_outbound.json ]]; then
        cp /tmp/nohara-node/custom_outbound.json /etc/nohara-node/
    fi
    if [[ ! -f /etc/nohara-node/custom_inbound.json ]]; then
        cp /tmp/nohara-node/custom_inbound.json /etc/nohara-node/
    fi
    if [[ ! -f /etc/nohara-node/rulelist ]]; then
        cp /tmp/nohara-node/rulelist /etc/nohara-node/
    fi

    curl -o /usr/bin/nanode -Ls https://github.com/nohara-cloud/nohara-node/raw/master/release/nanode.sh
    chmod +x /usr/bin/nanode
    cd $cur_dir
    
    echo -e ""
    echo "Nohara Node 管理脚本 nanode 使用方法: "
    echo "------------------------------------------"
    echo "nanode                    - 显示管理菜单 (功能更多)"
    echo "nanode start              - 启动 nohara-node"
    echo "nanode stop               - 停止 nohara-node"
    echo "nanode restart            - 重启 nohara-node"
    echo "nanode status             - 查看 nohara-node 状态"
    echo "nanode enable             - 设置 nohara-node 开机自启"
    echo "nanode disable            - 取消 nohara-node 开机自启"
    echo "nanode log                - 查看 nohara-node 日志"
    echo "nanode update             - 更新 nohara-node"
    echo "nanode update x.x.x       - 更新 nohara-node 指定版本"
    echo "nanode config             - 显示配置文件内容"
    echo "nanode install            - 安装 nohara-node"
    echo "nanode uninstall          - 卸载 nohara-node"
    echo "nanode version            - 查看 nohara-node 版本"
    echo "------------------------------------------"
}

echo -e "${green}开始安装${plain}"
install_base
# install_acme
install_nohara_node $1