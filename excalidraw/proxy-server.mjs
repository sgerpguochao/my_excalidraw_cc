#!/usr/bin/env node
/**
 * Excalidraw 简易反向代理
 * 将 80 端口请求转发到前端(3001)和协作(3002)
 * 使外网访问 http://117.50.174.50/ 时协作能同源连接
 *
 * 运行: node proxy-server.mjs
 * 需 root 或端口 80 权限，或修改 PORT 为 8080
 */

import http from "http";
import httpProxy from "http-proxy";

const FRONTEND_PORT = 3001;
const COLLAB_PORT = 3002;
const PROXY_PORT = parseInt(process.env.PROXY_PORT || process.env.PORT || "80", 10);

const proxy = httpProxy.createProxyServer({});

const server = http.createServer((req, res) => {
  if (req.url?.startsWith("/socket.io")) {
    proxy.web(req, res, { target: `http://127.0.0.1:${COLLAB_PORT}` });
    return;
  }
  proxy.web(req, res, { target: `http://127.0.0.1:${FRONTEND_PORT}` });
});

server.on("upgrade", (req, socket, head) => {
  if (req.url?.startsWith("/socket.io")) {
    proxy.ws(req, socket, head, { target: `http://127.0.0.1:${COLLAB_PORT}` });
    return;
  }
  proxy.ws(req, socket, head, { target: `http://127.0.0.1:${FRONTEND_PORT}` });
});

server.listen(PROXY_PORT, "0.0.0.0", () => {
  console.log(`Excalidraw 代理已启动: http://0.0.0.0:${PROXY_PORT}`);
  console.log(`  前端: -> :${FRONTEND_PORT}`);
  console.log(`  协作: /socket.io -> :${COLLAB_PORT}`);
});
