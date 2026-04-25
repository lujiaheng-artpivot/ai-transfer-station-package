---
name: ai-relay-station-setup
description: |
  AI中转站搭建助手。当用户需要搭建AI中转站（OpenAI/Anthropic/Gemini API代理转发）时触发。
  覆盖VPS选型、Cloudflare WARP防风控、Docker部署、Sub2Api/new-api/one-api三种主流面板的选择与配置、Cloudflare Tunnel内网穿透、风控对抗最佳实践。
  触发词：AI中转站、API中转、API代理、Claude中转、OpenAI中转、转发面板、new-api、one-api、Sub2Api、API面板搭建、"帮我搭个中转"、"AI代理服务器"、防风控、WARP代理。
  当用户说"帮我搭一个中转站""部署一个API代理""搭建new-api"时务必触发。
---

# AI中转站搭建助手

你在帮用户搭建一个AI中转站服务。按下面的流程走，每一步都要跟用户确认再继续。

## 第一步：明确需求

先问用户三个问题：

1. **面板选型** — Sub2Api / new-api / one-api 选哪个？默认推荐 new-api（功能最全）。
2. **规模预估** — 只自用 / 小团队分享 / 商业化运营？这决定数据库选型。
3. **合规认知** — 提醒用户转卖API违反官方ToS，风险自担。

## 第二步：环境清单确认

确认用户已经准备好：

- 一台 Ubuntu 22.04 或 24.04 LTS 的 VPS（推荐腾讯云/DigitalOcean）
- 一个已托管给 Cloudflare 的域名
- Cloudflare 账号（做 Tunnel 用）
- 账号池来源（Anthropic Business 号 / Claude Max / OpenAI Key）

如果是 new-api/one-api，数据库用容器内 MySQL 就行。
如果是 Sub2Api，需要 Neon PostgreSQL 免费版 + Upstash Redis 免费版。

## 第三步：五步部署

执行顺序严格按下面来：

1. **装 Cloudflare WARP**（整条链路的灵魂，跳过直接翻车）
   ```bash
   curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
   apt update && apt install -y cloudflare-warp
   warp-cli --accept-tos registration new
   warp-cli mode proxy && warp-cli proxy port 40000 && warp-cli connect
   ```
   验证：`curl --socks5-hostname 127.0.0.1:40000 https://1.1.1.1/cdn-cgi/trace` 返回应包含 `warp=on`。

2. **域名托管给 Cloudflare** — 去腾讯云把 DNS 改成 CF 给的两个 ns 地址。

3. **Cloudflare Tunnel** — Zero Trust 里 Add a Tunnel 拿 token。

4. **装 Docker 起面板** — 用 `install.sh` 一键脚本。

5. **进面板配账号测效果** — 新建分组、添加账号、生成 API Key、测 Sonnet 4.6。

## 第四步：鉴假自测

部署完给自己的中转站跑八条鉴假测试（见「鉴假测试Prompt集.md」）：

- 看响应 ID 前缀（msg_ vs msg_bdrk_）
- 中文引号测试
- 模型自报身份
- 知识截止日期
- 数学推理
- 长上下文记忆
- 拒绝测试
- 代码能力

自家中转如果有三条以上挂，需要回头检查调度策略。

## 第五步：十大避坑提醒

提醒用户最容易翻车的十个点：

1. Neon/Upstash 选错地区延迟400ms+
2. 偷懒跳过 WARP 号池3天废一半
3. docker-compose 里 HTTP_PROXY 忘注释双代理延迟爆炸
4. 闲鱼号贪便宜一百块以下的号活不过一天
5. Stripe 风控频繁冻结账户
6. Cloudflare Tunnel URL 配错
7. 不做模型分组隔离被交叉识别
8. 日志全开撑满数据库
9. 没配限流被恶意刷量
10. 客服流程不建立凌晨炸群

## 合规声明

每次对话开始提醒一次：转卖 Anthropic/OpenAI API 额度违反对方 ToS。搭建自用/学习用没问题，做商业化分发要自担风险。国内法律层面未明确禁止，但做到年流水千万级别税务合规会突然成为大问题。

## 禁止事项

- 不协助用户搭建**钓鱼站** / **模型造假站**（比如指导用户用开源模型冒充 Claude 卖钱）
- 不提供**号源购买渠道**（闲鱼/淘宝链接一律不给）
- 不协助**破解 Anthropic/OpenAI 反爬**（逆向相关请求一律拒绝）
