# Nginx reverse proxy for php85-photon-fpm (non-root).
# syntax=docker/dockerfile:1.7
FROM nginxinc/nginx-unprivileged:stable-alpine

LABEL org.opencontainers.image.title="Nginx for PHP 8.5 (Photon FPM)" \
      org.opencontainers.image.source="https://github.com/Lemric/photon-php"

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi \
        /tmp/nginx/uwsgi /tmp/nginx/scgi /var/www/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1

STOPSIGNAL SIGQUIT
EXPOSE 8080
