#!/bin/bash

echo "=== Cloudflare DNS-01 一键签证书脚本 ==="
read -p "请输入 Cloudflare API Token: " CF_Token
read -p "请输入要签发的域名（如 example.com）: " Domain

# 设置 Cloudflare Token 环境变量
export CF_Token="$CF_Token"

# 检查 jq 是否已安装
if ! command -v jq >/dev/null 2>&1; then
    echo "[+] 检测到未安装 jq，正在自动安装..."
    if command -v apt >/dev/null 2>&1; then
        apt update -y && apt install jq -y
    elif command -v yum >/dev/null 2>&1; then
        yum install jq -y
    elif command -v dnf >/dev/null 2>&1; then
        dnf install jq -y
    else
        echo "[!] 未找到可用的包管理器，请手动安装 jq 后重试。"
        exit 1
    fi
else
    echo "[+] jq 已安装。"
fi

# 安装 acme.sh（如果未安装）
if [ ! -d "$HOME/.acme.sh" ]; then
    echo "[+] 安装 acme.sh..."
    curl https://get.acme.sh | sh
    source ~/.bashrc
    export PATH="$HOME/.acme.sh:$PATH"
fi
export PATH="$HOME/.acme.sh:$PATH"

# 设置默认 CA
echo "[+] 设置默认 CA 为 Let's Encrypt..."
acme.sh --set-default-ca --server letsencrypt

# 申请证书
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$Domain" --keylength ec-256

# 定义证书路径
CERT_DIR="$HOME/.acme.sh/${Domain}_ecc"
CERT_FILE="${CERT_DIR}/fullchain.cer"
KEY_FILE="${CERT_DIR}/${Domain}.key"

# 检查文件是否存在
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    echo "[!] 证书生成失败，请检查 acme.sh 输出。"
    exit 1
fi

# 自动更新 V2bX 配置
CONFIG_FILE="/etc/V2bX/config.json"
BACKUP_FILE="/etc/V2bX/config.json.bak_$(date +%F_%H-%M-%S)"

if [ -f "$CONFIG_FILE" ]; then
    echo "[+] 备份原配置文件到 $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"

    echo "[+] 更新 V2bX 配置中 NodeType = vless 的节点证书..."
    jq --arg domain "$Domain" \
       --arg cert "$CERT_FILE" \
       --arg key "$KEY_FILE" \
       'map(if .NodeType == "vless" then
            .CertConfig.CertMode = "self" |
            .CertConfig.CertDomain = $domain |
            .CertConfig.CertFile = $cert |
            .CertConfig.KeyFile = $key
          else . end)' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"

    echo "[+] 已成功更新 V2bX 配置文件。"
else
    echo "[!] 未找到 /etc/V2bX/config.json，跳过修改。"
fi

echo
echo "=== 签发完成！证书路径如下 ==="
echo "CertFile: $CERT_FILE"
echo "KeyFile : $KEY_FILE"
echo
echo "acme.sh 已自动添加续期任务。"
