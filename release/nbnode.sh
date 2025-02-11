#!/bin/bash

# Constants
readonly GITHUB_BASE_URL="https://github.com/nohara-cloud/nboard-node"
readonly INSTALL_SCRIPT_URL="${GITHUB_BASE_URL}/raw/master/release/install.sh"
readonly BBR_SCRIPT_URL="https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
readonly SHELL_UPDATE_URL="${GITHUB_BASE_URL}/raw/master/release/nbnode.sh"

# System paths
readonly SERVICE_FILE="/etc/systemd/system/nboard-node.service"
readonly CONFIG_DIR="/etc/nboard-node"
readonly CONFIG_FILE="${CONFIG_DIR}/config.yml"
readonly BINARY_PATH="/usr/local/bin/nboard-node"

# Color definitions
declare -A COLORS=(
    ["red"]='\033[0;31m'
    ["green"]='\033[0;32m'
    ["yellow"]='\033[0;33m'
    ["plain"]='\033[0m'
)

# Status codes
readonly STATUS_RUNNING=0
readonly STATUS_STOPPED=1
readonly STATUS_NOT_INSTALLED=2

# Utility functions
log() {
    local level=$1
    local message=$2
    echo -e "${COLORS[$level]}${message}${COLORS[plain]}"
}

confirm() {
    local prompt=$1
    local default=${2:-"n"}
    
    if [[ $default == "y" ]]; then
        local hint="[Y/n]"
    else
        local hint="[y/N]"
    fi
    
    read -p "${prompt} ${hint}: " response
    response=${response:-$default}
    
    [[ ${response,,} == "y" ]]
}

check_root() {
    [[ $EUID -ne 0 ]] && log "red" "错误: 必须使用 root 用户运行此脚本！" && exit 1
}

# Service management functions
check_status() {
    if [[ ! -f $SERVICE_FILE ]]; then
        return $STATUS_NOT_INSTALLED
    fi
    
    if systemctl is-active --quiet nboard-node; then
        return $STATUS_RUNNING
    else
        return $STATUS_STOPPED
    fi
}

check_enabled() {
    systemctl is-enabled --quiet nboard-node
}

get_status_text() {
    check_status
    local status=$?
    case $status in
        $STATUS_RUNNING)
            echo -e "Nboard Node 状态: ${COLORS[green]}已运行${COLORS[plain]}"
            ;;
        $STATUS_STOPPED)
            echo -e "Nboard Node 状态: ${COLORS[yellow]}未运行${COLORS[plain]}"
            ;;
        $STATUS_NOT_INSTALLED)
            echo -e "Nboard Node 状态: ${COLORS[red]}未安装${COLORS[plain]}"
            ;;
    esac
    
    if [[ $status != $STATUS_NOT_INSTALLED ]]; then
        if check_enabled; then
            echo -e "是否开机自启: ${COLORS[green]}是${COLORS[plain]}"
        else
            echo -e "是否开机自启: ${COLORS[red]}否${COLORS[plain]}"
        fi
    fi
}

get_latest_version() {
    local version=$1
    if [[ -z "$version" ]]; then
        curl -Ls "$GITHUB_API_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        echo "${version#v}"
    fi
}

# Installation and update functions
install() {
    check_root
    bash <(curl -Ls $INSTALL_SCRIPT_URL)
    if [[ $? == 0 && ${1:-1} != 0 ]]; then
        start
    fi
}

uninstall() {
    if ! confirm "确定要卸载 Nboard Node 吗?" "n"; then
        return 0
    fi
    
    systemctl stop nboard-node
    systemctl disable nboard-node
    rm -f $SERVICE_FILE
    systemctl daemon-reload
    systemctl reset-failed
    rm -rf $CONFIG_DIR
    
    log "green" "卸载成功，如果你想删除此脚本，则退出脚本后运行 rm /usr/bin/nbnode -f 进行删除"
}

update() {
    local version=${1:-""}
    if [[ -z "$version" ]]; then
        version=$(get_latest_version)
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    
    bash <(curl -Ls $INSTALL_SCRIPT_URL) $version
    if [[ $? == 0 ]]; then
        log "green" "更新完成，已自动重启 Nboard Node，请使用 nbnode log 查看运行日志"
        exit 0
    fi
}

# Service control functions
start() {
    check_status
    if [[ $? == $STATUS_RUNNING ]]; then
        log "green" "Nboard Node 已运行，无需再次启动，如需重启请选择重启"
        return
    fi
    
    systemctl start nboard-node
    sleep 2
    check_status
    if [[ $? == $STATUS_RUNNING ]]; then
        log "green" "Nboard Node 启动成功，请使用 nbnode log 查看运行日志"
    else
        log "red" "Nboard Node 可能启动失败，请稍后使用 nbnode log 查看日志信息"
    fi
}

stop() {
    systemctl stop nboard-node
    sleep 2
    check_status
    if [[ $? == $STATUS_STOPPED ]]; then
        log "green" "Nboard Node 停止成功"
    else
        log "red" "Nboard Node 停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息"
    fi
}

restart() {
    systemctl restart nboard-node
    sleep 2
    check_status
    if [[ $? == $STATUS_RUNNING ]]; then
        log "green" "Nboard Node 重启成功，请使用 nbnode log 查看运行日志"
    else
        log "red" "Nboard Node 可能启动失败，请稍后使用 nbnode log 查看日志信息"
    fi
}

# Configuration and maintenance functions
config() {
    log "plain" "Nboard Node 在修改配置后会自动尝试重启"
    vi $CONFIG_FILE
    sleep 2
    
    check_status
    case $? in
        $STATUS_RUNNING)
            log "green" "Nboard Node 状态: 已运行"
            ;;
        $STATUS_STOPPED)
            if confirm "检测到您未启动 Nboard Node 或 Nboard Node 自动重启失败，是否查看日志？" "y"; then
                show_log
            fi
            ;;
        $STATUS_NOT_INSTALLED)
            log "red" "Nboard Node 状态: 未安装"
            ;;
    esac
}

show_log() {
    journalctl -u nboard-node.service -e --no-pager -f
}

install_bbr() {
    bash <(curl -L -s $BBR_SCRIPT_URL)
}

update_shell() {
    wget -O /usr/bin/nbnode -N --no-check-certificate $SHELL_UPDATE_URL
    if [[ $? != 0 ]]; then
        log "red" "下载脚本失败，请检查本机能否连接 Github"
        return 1
    fi
    
    chmod +x /usr/bin/nbnode
    log "green" "升级脚本成功，请重新运行脚本"
    exit 0
}

# Menu and usage functions
show_menu() {
    echo -e """
  ${COLORS[green]}Nboard Node 后端管理脚本，${COLORS[plain]}${COLORS[red]}不适用于 Docker 部署${COLORS[plain]}
--- https://github.com/nohara-cloud/nboard-node ---
  ${COLORS[green]}0.${COLORS[plain]} 修改配置
————————————————
  ${COLORS[green]}1.${COLORS[plain]} 安装 Nboard Node
  ${COLORS[green]}2.${COLORS[plain]} 更新 Nboard Node
  ${COLORS[green]}3.${COLORS[plain]} 卸载 Nboard Node
————————————————
  ${COLORS[green]}4.${COLORS[plain]} 启动 Nboard Node
  ${COLORS[green]}5.${COLORS[plain]} 停止 Nboard Node
  ${COLORS[green]}6.${COLORS[plain]} 重启 Nboard Node
  ${COLORS[green]}7.${COLORS[plain]} 查看 Nboard Node 状态
  ${COLORS[green]}8.${COLORS[plain]} 查看 Nboard Node 日志
————————————————
  ${COLORS[green]}9.${COLORS[plain]} 设置 Nboard Node 开机自启
 ${COLORS[green]}10.${COLORS[plain]} 取消 Nboard Node 开机自启
————————————————
 ${COLORS[green]}11.${COLORS[plain]} 一键安装 bbr (最新内核)
 ${COLORS[green]}12.${COLORS[plain]} 查看 Nboard Node 版本
 ${COLORS[green]}13.${COLORS[plain]} 升级维护脚本
"""
    get_status_text
    
    read -p "请输入选择 [0-13]: " choice
    handle_menu_choice $choice
}

show_usage() {
    echo "Nboard Node 管理脚本 nbnode 使用方法: "
    echo "------------------------------------------"
    echo "nbnode              - 显示管理菜单 (功能更多)"
    echo "nbnode start        - 启动 Nboard Node"
    echo "nbnode stop         - 停止 Nboard Node"
    echo "nbnode restart      - 重启 Nboard Node"
    echo "nbnode status       - 查看 Nboard Node 状态"
    echo "nbnode enable       - 设置 Nboard Node 开机自启"
    echo "nbnode disable      - 取消 Nboard Node 开机自启"
    echo "nbnode log          - 查看 Nboard Node 日志"
    echo "nbnode update       - 更新 Nboard Node"
    echo "nbnode update x.x.x - 更新 Nboard Node 指定版本"
    echo "nbnode install      - 安装 Nboard Node"
    echo "nbnode uninstall    - 卸载 Nboard Node"
    echo "nbnode version      - 查看 Nboard Node 版本"
    echo "------------------------------------------"
}

handle_menu_choice() {
    case "${1}" in
        0) config ;;
        1) install ;;
        2) update ;;
        3) uninstall ;;
        4) start ;;
        5) stop ;;
        6) restart ;;
        7) systemctl status nboard-node --no-pager -l ;;
        8) show_log ;;
        9) systemctl enable nboard-node ;;
        10) systemctl disable nboard-node ;;
        11) install_bbr ;;
        12) $BINARY_PATH version ;;
        13) update_shell ;;
        *) log "red" "请输入正确的数字 [0-13]" ;;
    esac
}

handle_command_line() {
    case "$1" in
        "start") start ;;
        "stop") stop ;;
        "restart") restart ;;
        "status") systemctl status nboard-node --no-pager -l ;;
        "enable") systemctl enable nboard-node ;;
        "disable") systemctl disable nboard-node ;;
        "log") show_log ;;
        "update") update "$2" ;;
        "config") config ;;
        "install") install ;;
        "uninstall") uninstall ;;
        "version") $BINARY_PATH version ;;
        "update_shell") update_shell ;;
        *) show_usage ;;
    esac
}

# Main execution
check_root

if [[ $# > 0 ]]; then
    handle_command_line "$@"
else
    show_menu
fi