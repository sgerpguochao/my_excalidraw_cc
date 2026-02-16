#!/bin/bash
# 启动反向代理，使外网可通过 http://117.50.174.50/ 访问（无需带端口）
# 协作功能将通过同源连接，无需单独开放 3002 端口
#
# 确保已运行 ./start.sh 启动前端和协作服务后，再执行本脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_PORT="${PROXY_PORT:-80}"  # 默认 80，需 root；可设为 8080: PORT=8080 ./start-proxy.sh

# 检查 3001 和 3002 是否在运行
if ! curl -s http://localhost:3001/ >/dev/null 2>&1; then
    echo "请先运行 ./start.sh 启动 Excalidraw"
    exit 1
fi
if ! curl -s http://localhost:3002/ >/dev/null 2>&1; then
    echo "协作服务未启动，请先运行 ./start.sh"
    exit 1
fi

cd "$SCRIPT_DIR"
echo "正在启动代理 (端口 $PROXY_PORT)..."
echo "访问: http://117.50.174.50${PROXY_PORT:-}:$PROXY_PORT/"
PROXY_PORT=$PROXY_PORT nohup node proxy-server.mjs >> proxy.log 2>&1 &
echo $! > .proxy.pid
sleep 1
if kill -0 $(cat .proxy.pid) 2>/dev/null; then
    echo "代理已启动，外网可访问 http://你的IP:$PROXY_PORT/"
else
    echo "启动失败，80 端口需 root 权限，可尝试: PROXY_PORT=8080 ./start-proxy.sh"
    rm -f .proxy.pid
fi
