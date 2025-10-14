#!/bin/bash
# 一键交互式签发单域名证书 (Cloudflare DNS-01)
# 作者: Mouse 定制交互版

echo "============================"
echo " Cloudflare DNS 签发证书"
echo "============================"
echo ""

# 用户交互输入
read -p "请输入 Cloudflare API Token: " CF_Token
read -p "请输入要签发证书的域名 (例如 example.com): " Domain
CertPath="/root/certs"

echo ""
echo ">>> 使用 Cloudflare Token: $CF_Token"
echo ">>> 目标域名: $Domain"
echo ">>> 证书目录: $CertPath"
echo ""

# 检查 acme.sh 是否安装
if ! command -v acme.sh &>/dev/null; then
    echo "正在安装 acme.sh ..."
    curl https://get.acme.sh | sh
    source ~/.bashrc
fi

# 设置环境变量
export CF_Token="$CF_Token"
export CF_Account_ID=""
export CF_Zone_ID=""

# 创建目录
mkdir -p "$CertPath"

# 签发证书
~/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d "$Domain" \
  --keylength ec-256 \
  --server letsencrypt

# 安装证书
~/.acme.sh/acme.sh --install-cert -d "$Domain" \
  --ecc \
  --key-file       "$CertPath/$Domain.key" \
  --fullchain-file "$CertPath/fullchain.cer"

echo ""
echo "✅ 证书签发完成！"
echo "证书文件已保存至：$CertPath"
ls -lh "$CertPath"

