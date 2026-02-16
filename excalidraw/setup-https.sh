#!/bin/bash
# Excalidraw HTTPS 配置脚本 (Nginx + Let's Encrypt)
#
# 前置条件：需要一个已解析到本机 IP 的域名
#   如 excalidraw.example.com -> 117.50.174.50
#
# 用法: sudo ./setup-https.sh your-domain.com
# 示例: sudo ./setup-https.sh excalidraw.mydomain.com

set -e

if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
    echo "用法: sudo ./setup-https.sh <域名>"
    echo "示例: sudo ./setup-https.sh excalidraw.example.com"
    echo ""
    echo "注意: Let's Encrypt 需要域名，不支持纯 IP。"
    echo "      请先将域名 A 记录解析到本机 IP (117.50.174.50)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Excalidraw HTTPS 配置 ==="
echo "域名: $DOMAIN"
echo ""

# 1. 安装 nginx 和 certbot
echo "1. 安装 nginx 和 certbot..."
apt-get update -qq
apt-get install -y nginx certbot python3-certbot-nginx

# 2. 确保 Excalidraw 和协作服务在运行
echo ""
echo "2. 检查 Excalidraw 服务..."
if ! curl -s http://127.0.0.1:3001/ >/dev/null 2>&1; then
    echo "   请先运行 ./start.sh 启动 Excalidraw"
    exit 1
fi
if ! curl -s http://127.0.0.1:3002/ >/dev/null 2>&1; then
    echo "   协作服务未启动，请先运行 ./start.sh"
    exit 1
fi
echo "   ✓ 服务已就绪"

# 3. 创建 certbot 验证目录
mkdir -p /var/www/certbot

# 4. 生成 nginx 配置
echo ""
echo "3. 配置 nginx..."
cat > /etc/nginx/sites-available/excalidraw << 'NGINX_HTTP'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
NGINX_HTTP

# 替换域名
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/excalidraw

# 禁用默认站点（若存在）
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/excalidraw /etc/nginx/sites-enabled/excalidraw

nginx -t && systemctl reload nginx
echo "   ✓ Nginx 已配置"

# 5. 获取 Let's Encrypt 证书
echo ""
echo "4. 获取 SSL 证书 (Let's Encrypt)..."
echo "   请确保域名 $DOMAIN 已解析到本机 IP"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || {
    echo ""
    echo "certbot 失败。请检查："
    echo "  1. 域名 $DOMAIN 的 A 记录是否指向 $(curl -s ifconfig.me 2>/dev/null || echo '本机公网IP')"
    echo "  2. 防火墙是否开放 80 端口"
    exit 1
}

# 6. 配置自动续期
echo ""
echo "5. 配置证书自动续期..."
systemctl enable certbot.timer 2>/dev/null || true

echo ""
echo "=== 配置完成 ==="
echo ""
echo "  访问地址: https://$DOMAIN/"
echo "  协作功能（实时协作）现已支持 HTTPS，可正常使用。"
echo ""
echo "  证书将自动续期，无需手动操作。"
echo ""
