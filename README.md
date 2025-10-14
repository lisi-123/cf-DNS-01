## 托管cloudflare的域名使用 DNS 签发证书

```bash
wget -O cf-dns.sh https://raw.githubusercontent.com/lisi-123/cf-DNS-01/main/cf-dns.sh && chmod +x cf-dns.sh && ./cf-dns.sh
```

<br>


## 🧩 一、Cloudflare API Token 是什么

Cloudflare 的 API Token 是一串密钥，允许脚本自动操作你的 Cloudflare 账户，
例如：

自动添加 / 删除 DNS 记录（签证书时用）

自动续签证书

无需人工登录 Cloudflare 网站

⚠️ 它只需要有「编辑 DNS 记录」权限，不必给整个账号权限。

## 🧭 二、获取步骤（新版界面）

① 登录 Cloudflare 控制台

👉 https://dash.cloudflare.com/profile/api-tokens


② 点击 “创建令牌”


③ 选择模板：

在“API 令牌模板”中，找到

“编辑区域 DNS”

然后点 “使用模板”


④ 设置权限与范围：

“特定区域”改为“所有区域”

其他内容保持默认即可


⑤ 点击底部的 “继续以显示摘要”


⑥ 复制生成的 Token，一串字母数字，比如：
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ...


这个就是脚本要填入的：

Cloudflare Token="eyJhbGciOiJI..."

<br><br><br>
