#!/bin/sh
set -e

# FTLCONF_ 环境变量由 compose.yaml 直接传入，这里不再重复设置
# 只做启动前的准备工作

mkdir -p /var/log /var/lib/unbound /etc/pihole /etc/supervisor.d

# 确保 root.hints 存在
if [ ! -s /var/lib/unbound/root.hints ]; then
    echo "[entrypoint] 下载 root.hints..."
    curl -sSo /var/lib/unbound/root.hints \
        https://www.internic.net/domain/named.root || true
fi

chown -R unbound:unbound /var/lib/unbound 2>/dev/null || true

echo "[entrypoint] 检查 Unbound 配置..."
unbound-checkconf && echo "[entrypoint] Unbound 配置 OK"

echo "[entrypoint] 启动 supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
