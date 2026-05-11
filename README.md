# Pi-hole + Unbound 单镜像 Docker

Pi-hole 和 Unbound 打包在**同一个容器**里，用 `supervisord` 统一管理两个进程。

- **Unbound** 监听 `127.0.0.1:5335`，作为本地递归 DNS，不依赖任何公共 DNS 服务商
- **Pi-hole** 负责广告拦截和 DNS 管理，以 Unbound 为唯一上游
- 默认开启 DNSSEC、bogus-private、domain-needed 等安全选项

## 目录结构

```
.
├── Dockerfile                            # 单镜像构建文件
├── docker-entrypoint.sh                  # 容器启动脚本
├── compose.yaml                          # Docker Compose 部署文件
├── .env.example                          # 环境变量模板
└── etc/
    ├── unbound/
    │   └── unbound.conf.d/
    │       └── pihole.conf               # Unbound 配置
    ├── supervisor.d/
    │   ├── unbound.ini                   # supervisord unbound 进程配置
    │   └── pihole.ini                    # supervisord pihole 进程配置
    └── supervisord/
        └── supervisord.conf              # supervisord 主配置
```

## 快速开始

### 方式一：docker run（最简单）

一条命令直接启动，无需克隆项目：

```bash
docker run -d \
  --name pihole-unbound \
  --restart unless-stopped \
  -e TZ="Asia/Shanghai" \
  -e PIHOLE_WEB_PASSWORD="你的密码" \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 8080:80/tcp \
  -v pihole_etc:/etc/pihole \
  -v unbound_var:/var/lib/unbound \
  --cap-add NET_ADMIN \
  --cap-add SYS_NICE \
  ghcr.io/sinoserendipity/pihole-unbound-docker:latest
```

启动后打开 Web 管理界面：`http://<主机IP>:8080/admin`

---

### 方式二：docker compose（推荐，便于管理）

**1. 克隆项目**

```bash
git clone https://github.com/sinoserendipity/pihole-unbound-docker.git
cd pihole-unbound-docker
```

**2. 配置环境变量**

```bash
cp .env.example .env
# 编辑 .env，至少改掉 PIHOLE_WEB_PASSWORD
```

**3. 启动**

```bash
docker compose up -d
```

**4. 打开 Web 管理界面**

```
http://<主机IP>:8080/admin
```

**5. 设置路由器 DNS**

在路由器 DHCP 设置中，将 DNS 服务器改为运行本容器的主机 IP，局域网内所有设备即可享受广告拦截。

---

## 常用命令

```bash
# 查看容器状态
docker compose ps

# 查看所有日志
docker compose logs -f

# 查看 supervisord 管理的进程状态
docker exec pihole-unbound supervisorctl status

# 测试 Unbound 递归解析（5335 端口）
docker exec pihole-unbound dig @127.0.0.1 -p 5335 cloudflare.com A

# 测试 Pi-hole DNS（53 端口）
dig @<主机IP> cloudflare.com

# 进入容器调试
docker exec -it pihole-unbound sh

# 更新到最新镜像
docker compose pull && docker compose up -d --force-recreate
```

---

## 53 端口被占用（Ubuntu / Debian 常见问题）

`systemd-resolved` 默认占用 53 端口，需要先禁用其 stub listener：

```bash
# 编辑配置
sudo nano /etc/systemd/resolved.conf

# 在 [Resolve] 下添加或修改：
# DNSStubListener=no

# 重启服务
sudo systemctl restart systemd-resolved
```

---

## 环境变量说明

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TZ` | `Asia/Shanghai` | 时区 |
| `PIHOLE_WEB_PASSWORD` | `change-me` | Web UI 密码 |
| `PIHOLE_WEB_PORT` | `8080` | Web UI 端口（仅 compose 方式） |

---

## 与双容器方案对比

| | 本项目（单容器） | 双容器方案 |
|---|---|---|
| 部署 | `docker run` 一条命令搞定 | 需要 docker-compose |
| 进程管理 | supervisord | Docker 容器间通信 |
| 网络配置 | 简单，无容器间网络 | 需要自定义 bridge 网络 |
| 更新灵活性 | 需重建镜像 | pihole/unbound 独立更新 |
| 资源隔离 | 共享（同一容器） | 隔离 |

---

## License

MIT
