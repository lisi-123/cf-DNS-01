#!/bin/bash
# 一键交互式签发单域名证书 (Cloudflare DNS-01)
# 作者: lisi-123

echo "============================"
echo " Cloudflare DNS 签发证书"
echo "============================"
echo ""

#!/bin/bash

echo "=== Cloudflare DNS-01 一键签证书脚本 ==="
read -p "请输入 Cloudflare API Token: " CF_Token
read -p "请输入要签发的域名（如 example.com）: " Domain

# 设置 Cloudflare Token 环境变量
export CF_Token="$CF_Token"

# 安装 acme.sh（如果未安装）
if [ ! -d "$HOME/.acme.sh" ]; then
    echo "[+] 安装 acme.sh..."
    curl https://get.acme.sh | sh
    # 让 acme.sh 立即可用
    source ~/.bashrc
    export PATH="$HOME/.acme.sh:$PATH"
fi

# 确保 acme.sh 命令可用
export PATH="$HOME/.acme.sh:$PATH"

# 固定为 Let's Encrypt
echo "[+] 设置默认 CA 为 Let's Encrypt..."
acme.sh --set-default-ca --server letsencrypt

# 使用 Cloudflare DNS 申请证书
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$Domain" --keylength ec-256

# 显示证书路径
echo
echo "=== 签发完成！证书已生成 ==="
echo "默认证书路径如下："
echo "/root/.acme.sh/${Domain}_ecc/${Domain}.key"
echo "/root/.acme.sh/${Domain}_ecc/fullchain.cer"
echo
echo "acme.sh 已自动添加续期任务。"
