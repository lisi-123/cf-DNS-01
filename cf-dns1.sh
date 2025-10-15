#!/bin/bash
# 一键交互式签发单域名证书 (Cloudflare DNS-01)
# 作者: lisi-123

echo "============================"
echo " Cloudflare DNS 签发证书"
echo "============================"

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
echo "[+] 正在申请证书..."
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$Domain" --keylength ec-256
if [ $? -ne 0 ]; then
    echo "[!] acme.sh 签发失败，请检查 Cloudflare Token 或域名配置。"
    exit 1
fi

# 定义证书路径
CERT_DIR="$HOME/.acme.sh/${Domain}_ecc"
CERT_FILE="${CERT_DIR}/fullchain.cer"
KEY_FILE="${CERT_DIR}/${Domain}.key"

# 检查文件是否存在
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    echo "[!] 证书文件不存在，请检查 acme.sh 输出。"
    exit 1
fi

# 自动更新 V2bX 配置
CONFIG_FILE="/etc/V2bX/config.json"
BACKUP_FILE="/etc/V2bX/config.json.bak_$(date +%F_%H-%M-%S)"

if [ -f "$CONFIG_FILE" ]; then
    echo "[+] 备份原配置文件到 $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"

    echo "[+] 正在更新 NodeType=vless 的节点配置..."
    jq --arg domain "$Domain" \
       --arg cert "$CERT_FILE" \
       --arg key "$KEY_FILE" \
       '
       if type == "array" then
           map(if .NodeType == "vless" then
               .CertConfig.CertMode = "self" |
               .CertConfig.CertDomain = $domain |
               .CertConfig.CertFile = $cert |
               .CertConfig.KeyFile = $key
           else . end)
       elif type == "object" and .Nodes then
           .Nodes |= map(if .NodeType == "vless" then
               .CertConfig.CertMode = "self" |
               .CertConfig.CertDomain = $domain |
               .CertConfig.CertFile = $cert |
               .CertConfig.KeyFile = $key
           else . end)
       else
           .
       end
       ' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"

    echo "[+] V2bX 配置更新完成。"
else
    echo "[!] 未找到 $CONFIG_FILE，跳过配置更新。"
fi

# 重启 V2bX
if systemctl list-units --type=service | grep -q "V2bX.service"; then
    echo "[+] 正在重启 V2bX 服务..."
    systemctl restart V2bX && echo "[+] V2bX 已重启完成。" || echo "[!] V2bX 重启失败，请手动检查。"
else
    echo "[!] 未检测到 V2bX.service，未执行重启。"
fi

echo
echo "=== 签发完成！证书路径如下 ==="
echo "CertFile: $CERT_FILE"
echo "KeyFile : $KEY_FILE"
echo
echo "acme.sh 已自动添加续期任务。"
