#!/bin/bash
# Excalidraw 启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$SCRIPT_DIR" || exit 1
PID_FILE="$SCRIPT_DIR/.excalidraw.pid"

# 检查是否已在运行（前端 3001 + 协作服务 3002）
if lsof -ti:3001 >/dev/null 2>&1 && lsof -ti:3002 >/dev/null 2>&1; then
    echo "Excalidraw 已在运行"
    echo "  前端: http://localhost:3001/"
    echo "  协作: 端口 3002"
    exit 0
fi

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖..."
    npm install
fi

# 启动协作服务器 (excalidraw-room, 端口 3002) - 实时协作必需
COLLAB_DIR="$WORKSPACE_DIR/excalidraw-room"
if [ -d "$COLLAB_DIR" ] && [ -f "$COLLAB_DIR/dist/index.js" ]; then
    if ! lsof -ti:3002 >/dev/null 2>&1; then
        echo "正在启动协作服务 (端口 3002)..."
        cd "$COLLAB_DIR" || true
        NODE_ENV=development PORT=3002 nohup node dist/index.js >> "$SCRIPT_DIR/excalidraw-room.log" 2>&1 &
        cd "$SCRIPT_DIR" || exit 1
        sleep 1
    fi
else
    echo "提示: 未找到 excalidraw-room，实时协作将不可用。可运行: git clone https://github.com/excalidraw/excalidraw-room.git"
fi

# 启动开发服务器（使用 npm 兼容方式，因系统可能无 yarn）
# BROWSER=none 防止在无 GUI 的服务器环境下因 xdg-open 不存在而崩溃
echo "正在启动 Excalidraw..."
cd "$SCRIPT_DIR/excalidraw-app" || exit 1
BROWSER=none nohup npx vite --host --open false >> "$SCRIPT_DIR/excalidraw.log" 2>&1 &
VITE_PID=$!
cd "$SCRIPT_DIR" || exit 1
echo $VITE_PID > "$PID_FILE"

# 等待服务启动
sleep 3
if kill -0 $VITE_PID 2>/dev/null; then
    echo ""
    echo "=========================================="
    echo "  Excalidraw 已启动"
    echo "  前端: http://localhost:3001/ 或 http://你的IP:3001/"
    echo "  协作: 端口 3002 (实时协作已启用)"
    echo "  使用 ./stop.sh 停止服务"
    echo ""
    echo "  外网访问 (需反向代理):"
    echo "    - nginx: 参考 nginx-excalidraw.conf"
    echo "    - 或运行: PORT=80 node proxy-server.mjs"
    echo "=========================================="
else
    echo "启动失败"
    rm -f "$PID_FILE"
    exit 1
fi
