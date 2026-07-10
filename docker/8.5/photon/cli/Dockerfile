# syntax=docker/dockerfile:1.7
#
# docker-library/php CLI layout for VMware Photon OS 5.x (legacy source build).
# Build: docker build -f cli/Dockerfile -t php:8.5.8-cli-photon .
# Context: docker/8.5/photon
#

ARG PHOTON_VERSION=5.0

FROM photon:${PHOTON_VERSION} AS builder

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

RUN --mount=type=cache,target=/var/cache/tdnf,sharing=locked \
	set -eux; \
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
	mkdir -p /var/www/html; \
	chmod 1777 /var/www/html

ENV PHP_INI_DIR=/usr/local/etc/php
RUN mkdir -p "$PHP_INI_DIR/conf.d"

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
	rm -rf "$GNUPGHOME" php.tar.xz.asc

COPY common/docker-php-ensure-re2c common/docker-php-source common/docker-php-build /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ensure-re2c /usr/local/bin/docker-php-source /usr/local/bin/docker-php-build \
	&& docker-php-ensure-re2c

ENV PHP_EXTRA_CONFIGURE_ARGS="--enable-phpdbg --enable-phpdbg-readline --enable-embed"
RUN docker-php-build compile

COPY common/docker-php-ext-configure common/docker-php-ext-enable common/docker-php-ext-install common/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-* /usr/local/bin/docker-php-entrypoint \
	&& set -eux; \
	if php -m | grep -qi sodium; then :; \
	elif [ -f "$(php-config --extension-dir)/sodium.so" ]; then docker-php-ext-enable sodium; fi; \
	php --version

COPY common/photon-runtime-cleanup.sh /usr/local/bin/photon-runtime-cleanup.sh
RUN chmod +x /usr/local/bin/photon-runtime-cleanup.sh && photon-runtime-cleanup.sh

FROM scratch AS runtime

COPY --from=builder / /

ENV NGINX_UID=82 \
    NGINX_GID=82

WORKDIR /var/www/html

USER ${NGINX_UID}:${NGINX_GID}

ENTRYPOINT ["/usr/local/bin/docker-php-entrypoint"]
CMD ["php", "-a"]
