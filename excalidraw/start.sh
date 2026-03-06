#!/bin/bash
# Excalidraw 启动脚本
# 使用 PM2 管理进程，支持自动重启

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Excalidraw 启动 ==="

cd "$SCRIPT_DIR" || exit 1
# 使用 PM2 ecosystem 配置文件启动
pm2 start ecosystem.config.js

echo ""
echo "=== 服务状态 ==="
pm2 list

echo ""
echo "访问地址:"
echo "  - http://localhost:3001/"
echo "  - https://117.50.174.50/ (通过 Nginx)"
echo ""
echo "使用 './stop.sh' 停止服务"
echo "使用 'pm2 logs' 查看日志"
