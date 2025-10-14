#!/bin/bash
# 一键签发 Cloudflare 泛域名证书脚本
# 仅需设置一次 API Token，其余全自动

# ======= 用户设置 =======
CF_Token="你的CloudflareAPIToken"
Domain="example.com"              # 你的主域名
CertPath="/root/certs"            # 证书保存目录
# ========================

# 安装 acme.sh（如果未安装）
if ! command -v acme.sh &>/dev/null; then
    echo "正在安装 acme.sh ..."
    curl https://get.acme.sh | sh
    source ~/.bashrc
fi

# 设置 Cloudflare 环境变量
export CF_Token="$CF_Token"
export CF_Account_ID=""  # 可空，不必填写
export CF_Zone_ID=""

# 创建证书保存目录
mkdir -p "$CertPath"

# 使用 Cloudflare DNS 自动签发泛域名证书
~/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d "$Domain" -d "*.$Domain" \
  --keylength ec-256 \
  --server letsencrypt

# 安装证书（复制到指定目录）
~/.acme.sh/acme.sh --install-cert -d "$Domain" \
  --ecc \
  --key-file       "$CertPath/$Domain.key" \
  --fullchain-file "$CertPath/fullchain.cer"

echo "✅ 证书签发完成"
echo "路径：$CertPath"
ls -lh "$CertPath"
