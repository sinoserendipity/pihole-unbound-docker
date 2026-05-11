# ============================================================
# Pi-hole + Unbound 单镜像
# 基于官方 Pi-hole 镜像（v6 起已改为 Alpine Linux）
# ============================================================

FROM pihole/pihole:latest

LABEL maintainer="you@example.com" \
      description="Pi-hole + Unbound all-in-one image" \
      org.opencontainers.image.source="https://github.com/you/pihole-unbound-docker"

# ------------------------------------------------------------------
# 安装 unbound 和 supervisord（Alpine apk）
# ------------------------------------------------------------------
RUN apk add --no-cache \
        unbound \
        supervisor \
        curl \
        bind-tools

# ------------------------------------------------------------------
# 下载 IANA 根信任锚
# ------------------------------------------------------------------
RUN mkdir -p /var/lib/unbound && \
    curl -sSo /var/lib/unbound/root.hints \
        https://www.internic.net/domain/named.root && \
    chown -R unbound:unbound /var/lib/unbound

# ------------------------------------------------------------------
# 配置文件
# Alpine supervisor 路径：
#   主配置 → /etc/supervisord.conf
#   子配置 → /etc/supervisor.d/*.ini
# ------------------------------------------------------------------
COPY etc/unbound/unbound.conf.d/pihole.conf /etc/unbound/unbound.conf.d/pihole.conf
COPY etc/supervisord/supervisord.conf       /etc/supervisord.conf
COPY etc/supervisor.d/unbound.ini           /etc/supervisor.d/unbound.ini
COPY etc/supervisor.d/pihole.ini            /etc/supervisor.d/pihole.ini

# ------------------------------------------------------------------
# 启动脚本
# ------------------------------------------------------------------
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 53/tcp 53/udp 80/tcp 443/tcp

ENTRYPOINT ["/docker-entrypoint.sh"]
