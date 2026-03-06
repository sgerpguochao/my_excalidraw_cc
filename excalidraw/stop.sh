#!/bin/bash
# Excalidraw 停止脚本
# 使用 PM2 管理进程

echo "正在停止 Excalidraw..."

# 停止 PM2 管理的进程
pm2 stop excalidraw-frontend excalidraw-collab 2>/dev/null

echo "Excalidraw 已停止"
echo ""
echo "使用 'pm2 status' 查看状态"
echo "使用 './start.sh' 启动服务"
