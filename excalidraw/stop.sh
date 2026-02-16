#!/bin/bash
# Excalidraw 停止脚本
# 终止端口 3001(前端) 和 3002(协作服务) 的进程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.excalidraw.pid"

stopped=0
for PORT in 3001 3002; do
    PIDS=$(lsof -ti:$PORT 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs -r kill 2>/dev/null
        sleep 1
        REMAINING=$(lsof -ti:$PORT 2>/dev/null)
        [ -n "$REMAINING" ] && echo "$REMAINING" | xargs -r kill -9 2>/dev/null
        [ $PORT -eq 3001 ] && echo "Excalidraw 前端已停止" || echo "协作服务已停止"
        stopped=1
    fi
done

[ $stopped -eq 0 ] && echo "Excalidraw 未在运行"

# 停止代理（若存在）
if [ -f "$SCRIPT_DIR/.proxy.pid" ]; then
    kill $(cat "$SCRIPT_DIR/.proxy.pid") 2>/dev/null
    rm -f "$SCRIPT_DIR/.proxy.pid"
fi
