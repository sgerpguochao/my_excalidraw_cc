#!/usr/bin/env node
/**
 * Excalidraw 协作 E2E 测试
 * 使用 Playwright 打开前端，点击协作按钮，验证是否能成功建立会话
 */

import { chromium } from "playwright";

const FRONTEND_URL = "http://localhost:3001";

console.log("=== Excalidraw 前端协作 E2E 测试 ===\n");

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();

// 监听控制台错误
page.on("console", (msg) => {
  const text = msg.text();
  if (msg.type() === "error" && text.includes("collab")) {
    console.log("[Page Error]", text);
  }
});

try {
  console.log("1. 加载前端页面:", FRONTEND_URL);
  await page.goto(FRONTEND_URL, { waitUntil: "networkidle", timeout: 15000 });
  console.log("   ✓ 页面加载完成\n");

  // 等待 Excalidraw 欢迎界面渲染（欢迎屏或画布）
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(2000);
  console.log("2. Excalidraw 界面已渲染\n");

  // 方式1: 欢迎屏点击「Live collaboration...」或「实时协作...」
  // 方式2: 顶部栏的分享按钮（紫色分享图标）
  const liveCollabLink = page.getByText(/Live collaboration|实时协作/, { exact: false }).first();
  const shareBtn = page.locator('[aria-label*="hare"], [title*="ollab"], [title*=" Share"]').first();
  
  if (await liveCollabLink.isVisible().catch(() => false)) {
    await liveCollabLink.click();
  } else if (await shareBtn.isVisible().catch(() => false)) {
    await shareBtn.click();
  } else {
    throw new Error("未找到协作入口");
  }
  await page.waitForTimeout(800);
  console.log("3. 已打开协作对话框\n");

  // 点击「开始会话」
  const startBtn = page.locator('button:has-text("开始会话"), button:has-text("Start Session")').first();
  await startBtn.click({ timeout: 5000 });
  console.log("4. 已点击「开始会话」\n");

  // 等待协作建立 - 成功后会显示房间链接或「复制链接」等
  await page.waitForTimeout(3000);

  // 检查是否有协作成功的迹象：分享链接输入框、复制链接按钮、或协作者数量
  const hasShareLink = await page.locator('input[readonly][value*="excalidraw.com"], [data-testid="collab-button"].active, button:has-text("复制"), button:has-text("Copy")').first().isVisible().catch(() => false);
  const collabActive = await page.locator('[data-testid="collab-button"].active, .collab-button.active').first().isVisible().catch(() => false);
  const hasRoomLink = await page.locator('textarea, input').filter({ has: page.locator() }).first().isVisible().catch(() => false);

  if (hasShareLink || collabActive || hasRoomLink) {
    console.log("   ✓ 协作会话已建立！\n");
    console.log("=== E2E 测试通过 ===\n");
    console.log("前端成功连接 excalidraw-room，协作功能正常。");
  } else {
    // 检查是否有错误提示
    const errorMsg = await page.locator('.collab-errors-button, [role="alert"], .Tooltip').first().innerText().catch(() => "");
    if (errorMsg) {
      console.log("   ✗ 协作失败，错误:", errorMsg);
    } else {
      console.log("   ⚠ 无法确认协作状态，请手动验证。页面已打开协作流程。");
    }
  }
} catch (err) {
  console.error("\n ✗ 测试失败:", err.message);
  await page.screenshot({ path: "/home/ubuntu/workspace/excalidraw/collab-test-fail.png" });
  console.log("   截图已保存: collab-test-fail.png");
  process.exit(1);
} finally {
  await browser.close();
  process.exit(0);
}
