# AI中转站自救/自建资料包 · v2.0

卡兹克整理 · 2026年4月版

## 里面有什么

### 一键部署
- `install.sh` — 交互式一键部署脚本，支持三个主流面板任选：Sub2Api / new-api / one-api。Ubuntu 22.04/24.04 下跑 `./install.sh` 自动装 Docker + Cloudflare WARP + 启动容器。
- `docker-compose.yml` — Sub2Api 基础编排模板，install.sh 会自动生成对应面板的版本，这个是手动微调用的。
- `一行命令.md` — 怎么把 install.sh 配成一行命令让读者直接跑。

### 选型和背景
- `开源中转面板清单.md` — 真实存在的主流开源面板清单（new-api / one-api / Sub2Api / openai-forward / NextChat），每个都标注了GitHub、特点和适用场景。

### 避坑和鉴假
- `搭建避坑清单.md` — 十个最容易翻车的坑，按踩坑顺序排好。
- `鉴假测试Prompt集.md` — 八条测试 prompt，你自己的站或别人家的站都能用。

### Claude Code 智能部署助手
- `claude-skill/SKILL.md` — 把这个文件丢进 Claude Code 的 skills 目录，Claude 就能当你的搭建顾问。你跟它说「帮我搭一个 new-api」，它会一步步带你走完整个流程，并强制做合规提醒和安全检查。

## 快速开始

**选项A · 最快路径**（适合技术熟手）
```bash
# 1. 租一台 Ubuntu 24.04 VPS
# 2. 上传资料包
scp AI中转站资料包.zip root@你的IP:~
ssh root@你的IP
unzip AI中转站资料包.zip -d relay && cd relay

# 3. 一行命令起环境
bash install.sh
# 交互式选择面板，自动装WARP/Docker/容器

# 4. 编辑 ~/relay-station/docker-compose.yml 填密钥
vim ~/relay-station/docker-compose.yml

# 5. 启动
cd ~/relay-station && docker compose up -d
```

**选项B · Claude 指导部署**（适合非技术用户）
把 `claude-skill/SKILL.md` 复制到你的 Claude Code `.claude/skills/` 目录，然后让 Claude 带你走。

**选项C · 分析已用的中转站**
直接打开 `鉴假测试Prompt集.md`，八条依次扔给你现在充过钱的那家中转站，看看它是不是在糊弄你。

## 三个面板怎么选

| 场景 | 推荐面板 | 原因 |
|-----|---------|-----|
| 只想自用 | one-api | 极简稳定，个人用足够 |
| 做成工作室规模 | new-api | 功能最全，50+渠道支持，中文社区活跃 |
| 想做差异化定价/订阅制 | Sub2Api | 分组倍率灵活 |

## 免责

这份资料基于公开信息整理，仅用于学习研究与个人自建。转卖 Anthropic/OpenAI API 额度违反对方 Terms of Service，请自行评估合规风险。做到一定规模需要处理税务合规问题。
