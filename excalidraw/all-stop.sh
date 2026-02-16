#!/bin/bash
# Excalidraw 总停止脚本（Excalidraw + Nginx）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "=== Excalidraw 总停止 ==="
echo ""

# 1. 停止 Excalidraw（前端 3001 + 协作 3002）
./stop.sh

# 2. 停止 Nginx
if command -v nginx &>/dev/null && systemctl is-active --quiet nginx 2>/dev/null; then
    echo "正在停止 Nginx..."
    sudo systemctl stop nginx 2>/dev/null && echo "  ✓ Nginx 已停止" || echo "  提示: 需 sudo 权限停止 Nginx"
fi

echo ""
echo "=== 已全部停止 ==="
