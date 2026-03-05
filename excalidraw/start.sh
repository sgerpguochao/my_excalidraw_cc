#!/bin/bash
# Excalidraw 启动脚本
# 使用 PM2 管理进程，支持自动重启

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Excalidraw 启动 ==="

# 检查 PM2 是否已有保存的进程
if pm2 describe excalidraw-frontend >/dev/null 2>&1; then
    echo "使用 PM2 启动已保存的服务..."
    pm2 start all
else
    echo "首次配置 PM2..."
    
    # 启动协作服务
    cd "$WORKSPACE_DIR/excalidraw-room" || exit 1
    NODE_ENV=development PORT=3002 pm2 start dist/index.js --name excalidraw-collab
    
    # 启动前端
    cd "$SCRIPT_DIR/excalidraw-app" || exit 1
    pm2 start npx --name excalidraw-frontend -- vite --host --port 3001
    
    # 保存进程列表以便服务器重启后自动启动
    pm2 save
    
    cd "$SCRIPT_DIR" || exit 1
fi

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
