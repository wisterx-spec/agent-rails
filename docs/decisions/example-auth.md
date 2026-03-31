---
topic: 认证方案选型
date: 2024-01-01
status: active
affects:
  - backend/app/routers/auth/
  - backend/app/middleware/
  - frontend/src/api/
  - frontend/src/store/auth/
---
<!-- QUICK: NEVER 换成 Session Cookie | NEVER token 存 localStorage | NEVER TTL 超 2 小时 -->

# 使用 JWT Bearer Token 而非 Session Cookie

> ⚠️ 这是示例文件，展示决策记录的写法。请根据实际项目替换。

## 背景

系统需要同时支持 Web 端和移动端（iOS / Android）。移动端无法像浏览器一样可靠地管理 Cookie，尤其是在跨域和 WebView 场景下行为不一致。

## 决定

使用 JWT Bearer Token 作为认证凭证，前端统一在 `Authorization: Bearer <token>` 头中传递。

## 原因

1. **移动端兼容**：JWT 是标准 HTTP Header，在所有客户端上行为一致
2. **无状态**：服务端不需要维护 Session Store，便于水平扩展
3. **跨域友好**：不依赖 Cookie，CORS 配置更简单

## 代价与权衡

- **Token 无法主动吊销**：用户登出后 Token 仍在有效期内有效（用短期 TTL 1小时 + refresh token 缓解）
- **Token 泄露风险**：存储在 localStorage 有 XSS 风险（缓解：存在内存中，refresh token 存 httpOnly Cookie）
- **refresh token 轮换**：需要维护一套 refresh token 轮换逻辑，增加了复杂度

## 禁止事项

- **NEVER** 把 JWT 换成纯 Session Cookie，除非移动端客户端需求消失
- **NEVER** 把 access token TTL 调长到超过 2 小时（会使 Token 吊销窗口过长）
- **NEVER** 把 access token 存入 localStorage（XSS 可直接读取）
- **NEVER** 在接口层绕过 JWT 验证中间件（哪怕是"内部接口"）

## 例外场景

- Webhook 回调接口（来自第三方，使用 HMAC 签名验证，不使用 JWT）
- 健康检查接口 `/api/health`（公开，无需认证）
