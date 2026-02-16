#!/bin/bash
# Excalidraw 自签名 HTTPS（适用于无域名、仅 IP 访问的场景）
# 浏览器会提示不安全，需手动点击「高级」->「继续访问」
# 自签名证书下 crypto.subtle 可用，协作功能可正常使用
#
# 用法: sudo ./setup-https-selfsigned.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

echo "=== Excalidraw 自签名 HTTPS 配置 ==="
echo ""

# 安装 nginx
if ! command -v nginx &>/dev/null; then
    echo "1. 安装 nginx..."
    apt-get update -qq && apt-get install -y nginx
else
    echo "1. Nginx 已安装"
fi

# 检查服务
echo ""
echo "2. 检查 Excalidraw 服务..."
if ! curl -s http://127.0.0.1:3001/ >/dev/null 2>&1; then
    echo "   请先运行 ./start.sh 启动 Excalidraw"
    exit 1
fi
echo "   ✓ 服务已就绪"

# 生成自签名证书
CERT_DIR="/etc/nginx/ssl/excalidraw"
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/cert.pem" ]; then
    echo ""
    echo "3. 生成自签名证书 (有效期 365 天)..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/key.pem" \
        -out "$CERT_DIR/cert.pem" \
        -subj "/CN=excalidraw/O=Excalidraw/C=CN"
    echo "   ✓ 证书已生成"
else
    echo "3. 证书已存在"
fi

# Nginx 配置 - 监听 443，支持 IP 访问
echo ""
echo "4. 配置 nginx..."
cat > /etc/nginx/sites-available/excalidraw << 'NGINX_CFG'
# HTTP 自动跳转 HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;

    ssl_certificate /etc/nginx/ssl/excalidraw/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/excalidraw/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

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
NGINX_CFG

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/excalidraw /etc/nginx/sites-enabled/excalidraw

nginx -t && systemctl reload nginx

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=== 配置完成 ==="
echo ""
echo "  访问地址: https://$IP/ 或 https://117.50.174.50/"
echo "  首次访问浏览器会提示「不安全」，点击「高级」->「继续访问」即可。"
echo "  协作功能在 HTTPS 下可正常使用。"
echo ""
