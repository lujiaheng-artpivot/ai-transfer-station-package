#\!/bin/bash
# AI中转站一键部署脚本 · v2.0
# 支持三个主流开源面板：Sub2Api / new-api / one-api
# 适用：Ubuntu 22.04 / 24.04 LTS + Debian 12

set -e

echo "============================================"
echo "  AI中转站一键部署脚本 v2.0"
echo "  支持面板：Sub2Api | new-api | one-api"
echo "============================================"

# ========== 面板选择 ==========
echo ""
echo "请选择要部署的中转面板："
echo "  [1] Sub2Api       (weishaw/sub2api,  配置简单，订阅式)"
echo "  [2] new-api       (Calcium-Ion,      功能最全，中文社区最活跃)"
echo "  [3] one-api       (songquanpeng,     元老级项目，稳定)"
read -p "输入数字 [1-3]: " panel_choice

case $panel_choice in
    1) PANEL="sub2api"  ;;
    2) PANEL="new-api"  ;;
    3) PANEL="one-api"  ;;
    *) echo "无效选项"; exit 1 ;;
esac
echo "已选：$PANEL"

# ========== 系统准备 ==========
echo ""
echo "=== [1/5] 更新系统 ==="
apt update && apt install -y curl gpg lsb-release ca-certificates

# ========== 装Cloudflare WARP ==========
echo ""
echo "=== [2/5] 装Cloudflare WARP(防风控核心) ==="
if \! command -v warp-cli &> /dev/null; then
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
    apt update && apt install -y cloudflare-warp
fi
systemctl enable --now warp-svc
sleep 3

# 注册设备(已注册则跳过)
if \! warp-cli status 2>/dev/null | grep -q "Registered"; then
    warp-cli --accept-tos registration new
fi
warp-cli mode proxy
warp-cli proxy port 40000
warp-cli connect
sleep 2

echo "--- WARP流量探针 ---"
if curl -m 10 --socks5-hostname 127.0.0.1:40000 https://1.1.1.1/cdn-cgi/trace 2>/dev/null | grep -q "warp=on"; then
    echo "✓ WARP代理已接管出境流量"
else
    echo "✗ WARP代理未生效，请检查network"; exit 1
fi

# ========== 装Docker ==========
echo ""
echo "=== [3/5] 装Docker ==="
if \! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
fi
docker --version

# ========== 按选择的面板生成compose文件 ==========
echo ""
echo "=== [4/5] 生成$PANEL的docker-compose.yml ==="
mkdir -p ~/relay-station && cd ~/relay-station

case $PANEL in
    sub2api)
        cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  sub2api:
    image: weishaw/sub2api:latest
    container_name: sub2api_core
    restart: always
    network_mode: "host"
    environment:
      - TZ=Asia/Shanghai
      - SERVER_PORT=8080
      - DATABASE_HOST=<NEON_HOST>
      - DATABASE_USER=<NEON_USER>
      - DATABASE_PASSWORD=<NEON_PASSWORD>
      - DATABASE_DBNAME=neondb
      - REDIS_HOST=<UPSTASH_HOST>
      - REDIS_PASSWORD=<UPSTASH_TOKEN>
      - REDIS_USE_TLS=true
COMPOSE_EOF
        ;;
    new-api)
        cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  new-api:
    image: calciumion/new-api:latest
    container_name: new-api
    restart: always
    ports:
      - "3000:3000"
    environment:
      - TZ=Asia/Shanghai
      - SQL_DSN=<MYSQL_USER>:<MYSQL_PASS>@tcp(mysql:3306)/new-api
      - REDIS_CONN_STRING=redis://redis:6379
    depends_on:
      - mysql
      - redis
    volumes:
      - ./data:/data
      - ./logs:/app/logs
  mysql:
    image: mysql:8.2
    container_name: new-api-mysql
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=<MYSQL_PASS>
      - MYSQL_DATABASE=new-api
    volumes:
      - ./mysql:/var/lib/mysql
  redis:
    image: redis:latest
    container_name: new-api-redis
    restart: always
COMPOSE_EOF
        ;;
    one-api)
        cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  one-api:
    image: justsong/one-api:latest
    container_name: one-api
    restart: always
    ports:
      - "3000:3000"
    environment:
      - TZ=Asia/Shanghai
      - SQL_DSN=<MYSQL_USER>:<MYSQL_PASS>@tcp(mysql:3306)/oneapi
    depends_on:
      - mysql
    volumes:
      - ./data:/data
      - ./logs:/app/logs
  mysql:
    image: mysql:8.2
    container_name: one-api-mysql
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=<MYSQL_PASS>
      - MYSQL_DATABASE=oneapi
    volumes:
      - ./mysql:/var/lib/mysql
COMPOSE_EOF
        ;;
esac

# Cloudflare Tunnel 追加
cat >> docker-compose.yml << 'COMPOSE_EOF'
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: always
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=<CF_TUNNEL_TOKEN>
    network_mode: host
COMPOSE_EOF

echo ""
echo "docker-compose.yml已生成在 ~/relay-station/"
echo ""
echo "=== [5/5] 下一步操作 ==="
echo ""
echo "  1. 编辑 ~/relay-station/docker-compose.yml"
echo "     把所有<...>字段填上真实的值："
echo "        - Neon数据库(sub2api)或MySQL密码(new-api/one-api)"
echo "        - Upstash Redis(sub2api需要)"
echo "        - Cloudflare Tunnel Token"
echo ""
echo "  2. 启动服务："
echo "     cd ~/relay-station && docker compose up -d"
echo ""
echo "  3. 查看日志："
echo "     docker compose logs -f"
echo ""
echo "  4. 打开你的域名登录，配置账号池，生成API Key"
echo ""
echo "=========================================="
echo "  环境已就绪，祝你搭建顺利"
echo "=========================================="
