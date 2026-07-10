# Nginx reverse proxy for php85-photon-fpm (non-root).
FROM nginxinc/nginx-unprivileged:stable-alpine

LABEL org.opencontainers.image.title="Nginx for PHP 8.5 (Photon FPM)" \
      org.opencontainers.image.source="https://github.com/Lemric/photon-php"

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi \
        /tmp/nginx/uwsgi /tmp/nginx/scgi /var/www/html

EXPOSE 8080
