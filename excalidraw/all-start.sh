#!/bin/bash
# Excalidraw 总启动脚本（前端 + 协作 + Nginx HTTPS）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "=== Excalidraw 总启动 ==="
echo ""

# 1. 启动 Excalidraw（前端 3001 + 协作 3002）
if ./start.sh; then
    echo ""
else
    echo "Excalidraw 启动失败"
    exit 1
fi

# 2. 启动 Nginx（HTTPS 443）
if command -v nginx &>/dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo "Nginx 已在运行"
    else
        echo "正在启动 Nginx..."
        sudo systemctl start nginx 2>/dev/null && echo "  ✓ Nginx 已启动" || echo "  提示: 需 sudo 权限启动 Nginx"
    fi
    echo ""
    echo "HTTPS 访问: https://117.50.174.50/"
else
    echo "提示: 未安装 Nginx，请用 http://IP:3001 访问"
fi

echo ""
echo "=== 启动完成 ==="
