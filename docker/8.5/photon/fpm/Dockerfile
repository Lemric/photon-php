#
# docker-library/php FPM layout for VMware Photon OS 5.x
# https://github.com/docker-library/php/blob/master/8.5/alpine3.23/fpm/Dockerfile
#
# Build: docker build -f fpm/Dockerfile -t php:8.5.8-fpm-photon .
# Context: docker/8.5/photon
#

FROM photon:5.0

RUN set -eux; \
	if [ -f /etc/tdnf/tdnf.conf ]; then \
		grep -q '^excludepkgs' /etc/tdnf/tdnf.conf || \
		echo 'excludepkgs=php,php-cli,php-fpm,php-common' >> /etc/tdnf/tdnf.conf; \
	fi

ENV PHPIZE_DEPS \
		autoconf \
		automake \
		libtool \
		pkg-config \
		gcc \
		libstdc++-devel \
		make \
		file \
		findutils \
		which

RUN set -eux; \
	tdnf makecache; \
	tdnf install -y \
		ca-certificates \
		curl \
		xz \
		tar \
		shadow \
		util-linux \
		gnupg \
		gawk \
		grep \
		sed \
		binutils \
		$PHPIZE_DEPS \
	; \
	tdnf clean all

RUN set -eux; \
	getent group nginx >/dev/null || groupadd -r nginx; \
	id -u nginx >/dev/null 2>&1 || useradd -u 82 -r -g nginx -s /sbin/nologin nginx; \
	mkdir -p /var/www/html; \
	chown nginx:nginx /var/www/html; \
	chmod 1777 /var/www/html

ENV PHP_INI_DIR=/usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS 1198C0117593497A5EC5C199286AF1F9897469DC 49D9AF6BC72A80D6691719C8AA23F5BE9C7097D4 D95C03BC702BE9515344AE3374E44BC9067701A5

ENV PHP_VERSION=8.5.8
ENV PHP_URL="https://www.php.net/distributions/php-8.5.8.tar.xz" PHP_ASC_URL="https://www.php.net/distributions/php-8.5.8.tar.xz.asc"
ENV PHP_SHA256="58910198d19e873048fe87cdfe16bc790025417ede3d1651bfa1c4b533d573f2"

RUN set -eux; \
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	echo "${PHP_SHA256}  php.tar.xz" | sha256sum -c -; \
	curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	done; \
	gpg --batch --verify php.tar.xz.asc php.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"

COPY common/docker-php-ensure-re2c common/docker-php-source common/docker-php-build /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ensure-re2c /usr/local/bin/docker-php-source /usr/local/bin/docker-php-build \
	&& docker-php-ensure-re2c

ENV PHP_EXTRA_CONFIGURE_ARGS="--disable-phpdbg --disable-cgi --enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx"
RUN docker-php-build compile

COPY common/docker-php-ext-configure common/docker-php-ext-enable common/docker-php-ext-install common/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-* /usr/local/bin/docker-php-entrypoint \
	&& set -eux; \
	if php -m | grep -qi sodium; then :; \
	elif [ -f "$(php-config --extension-dir)/sodium.so" ]; then docker-php-ext-enable sodium; fi

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
	cd "${PHP_INI_DIR%/php}"; \
	cp -v php-fpm.conf.default php-fpm.conf; \
	cp -v php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	grep -E '^listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
	sed -ri 's/^(listen = 127.0.0.1:9000)/;\1/' php-fpm.d/www.conf; \
	grep -E '^;listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/2 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
		echo; \
		echo '; default listen address for easy override in later php-fpm.d/*.conf files'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '; the [www] ini section below is for backwards compatibility and will be removed in 8.6+'; \
		echo '[www]'; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/docker-fpm.ini"

STOPSIGNAL SIGQUIT
EXPOSE 9000
CMD ["php-fpm"]
