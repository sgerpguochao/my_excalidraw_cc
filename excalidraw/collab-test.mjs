#!/usr/bin/env node
/**
 * 协作功能测试脚本
 * 模拟前端连接 excalidraw-room，验证 WebSocket 协作是否正常
 */

import { io } from "socket.io-client";

const COLLAB_URL = "http://localhost:3002";
const TEST_ROOM = "test-room-" + Date.now();

console.log("=== Excalidraw 协作功能测试 ===\n");
console.log("1. 连接协作服务器:", COLLAB_URL);

const socket = io(COLLAB_URL, {
  transports: ["websocket", "polling"],
  timeout: 5000,
});

const timeout = (ms) =>
  new Promise((_, reject) =>
    setTimeout(() => reject(new Error("超时")), ms)
  );

try {
  // 测试连接
  await Promise.race([
    new Promise((resolve) => socket.once("connect", resolve)),
    timeout(5000),
  ]);
  console.log("   ✓ 连接成功 (socket.id:", socket.id, ")\n");

  // 测试加入房间
  console.log("2. 加入测试房间:", TEST_ROOM);
  socket.emit("join-room", TEST_ROOM);

  const firstInRoom = await Promise.race([
    new Promise((resolve) => socket.once("first-in-room", () => resolve(true))),
    new Promise((resolve) => socket.once("new-user", () => resolve(false))),
    timeout(3000),
  ]);

  console.log("   ✓ 房间加入成功");
  console.log("   ", firstInRoom ? "(首个用户)" : "(有其他人)");

  // 测试 room-user-change
  const userChange = await Promise.race([
    new Promise((resolve) =>
      socket.once("room-user-change", (users) => resolve(users))
    ),
    timeout(2000),
  ]);
  console.log("   ✓ 用户列表:", userChange?.length || 0, "人\n");

  console.log("=== 协作测试通过 ===\n");
  console.log("excalidraw-room 运行正常，前端可正常建立协作会话。");
} catch (err) {
  console.error("\n ✗ 测试失败:", err.message);
  process.exit(1);
} finally {
  socket.disconnect();
  process.exit(0);
}
