#!/bin/bash
# Excalidraw 总启动脚本（前端 + 协作 + Nginx HTTPS）
# 使用 PM2 管理进程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Excalidraw 总启动 (PM2) ==="
echo ""

# 使用 PM2 启动服务
cd "$SCRIPT_DIR" || exit 1
./start.sh

# Nginx 启动
echo ""
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
echo ""
echo "管理命令:"
echo "  停止: ./stop.sh"
echo "  状态: pm2 status"
echo "  日志: pm2 logs"
