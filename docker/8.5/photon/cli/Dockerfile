#
# docker-library/php layout adapted for VMware Photon OS 5.x
# Same structure, scripts and /usr/local install path as official images:
# https://github.com/docker-library/php/tree/master/8.5/trixie/cli
#

FROM photon:5.0

# prevent distro PHP packages from shadowing /usr/local build
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
		gcc-c++ \
		make \
		re2c \
		file \
		findutils \
		which

RUN set -eux; \
	tdnf makecache; \
	tdnf install -y \
		$PHPIZE_DEPS \
		ca-certificates \
		curl \
		xz \
		tar \
		shadow \
		gnupg2 \
		gawk \
		grep \
		sed \
		binutils \
	; \
	tdnf clean all

# Photon OS ships re2c 1.x; PHP 8.5 requires re2c >= 3.x
RUN set -eux; \
	re2c_ver="$(re2c --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo 0)"; \
	if awk "BEGIN {exit !($re2c_ver >= 3.0)}"; then \
		echo "re2c $re2c_ver is sufficient"; \
	else \
		tdnf install -y cmake gcc gcc-c++ make tar xz curl; \
		cd /tmp; \
		curl -fsSL -o re2c.tar.xz https://github.com/skvadrik/re2c/releases/download/3.1/re2c-3.1.tar.xz; \
		tar -xf re2c.tar.xz; \
		cd re2c-3.1; \
		cmake -DCMAKE_BUILD_TYPE=Release -DRE2C_BUILD_RE2GO=OFF .; \
		make -j"$(nproc)"; \
		make install; \
		rm -rf /tmp/re2c-3.1 /tmp/re2c.tar.xz; \
	fi; \
	re2c --version

ENV PHP_INI_DIR=/usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown nginx:nginx /var/www/html 2>/dev/null || chown nobody:nobody /var/www/html; \
	chmod 1777 /var/www/html

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
	echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	done; \
	gpg --batch --verify php.tar.xz.asc php.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"

COPY docker-php-source /usr/local/bin/

RUN set -eux; \
	rpm -qa --queryformat '%{NAME}\n' | sort > /tmp/rpm-before.txt; \
	tdnf install -y \
		openssl-devel \
		libcurl-devel \
		oniguruma-devel \
		readline-devel \
		sqlite-devel \
		libxml2-devel \
		zlib-devel \
		libsodium-devel \
		libargon2-devel \
	; \
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
		PHP_BUILD_PROVIDER='https://github.com/docker-library/php' \
		PHP_UNAME='Linux - Docker - Photon OS' \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(gcc -dumpmachine)"; \
	libdir='lib'; \
	if [ -d /usr/lib64 ]; then libdir='lib64'; fi; \
	if [ ! -d /usr/include/curl ] && [ -d "/usr/include/${libdir}/curl" ]; then \
		ln -sT "/usr/include/${libdir}/curl" /usr/local/include/curl; \
	fi; \
	extraConfigure=; \
	if pkg-config --exists libargon2 2>/dev/null; then \
		extraConfigure="$extraConfigure --with-password-argon2"; \
	fi; \
	if pkg-config --exists libsodium 2>/dev/null; then \
		extraConfigure="$extraConfigure --with-sodium=shared"; \
	fi; \
	test "$PHP_INI_DIR" != "${PHP_INI_DIR%/php}"; \
	./configure \
		--build="$gnuArch" \
		--sysconfdir="${PHP_INI_DIR%/php}" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--with-pic \
		--enable-mbstring \
		--enable-mysqlnd \
		$extraConfigure \
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		--with-curl \
		--with-iconv \
		--with-openssl \
		--with-readline \
		--with-zlib \
		--enable-phpdbg \
		--enable-phpdbg-readline \
		--with-pear \
		--with-libdir="$libdir" \
		--enable-embed \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	cd /; \
	docker-php-source delete; \
	rpm -qa --queryformat '%{NAME}\n' | sort > /tmp/rpm-after.txt; \
	comm -13 /tmp/rpm-before.txt /tmp/rpm-after.txt \
		| grep -Ev '^(openssl|libcurl|oniguruma|readline|sqlite|libxml2|zlib|libsodium|libargon2|filesystem|glibc|photon)' \
		| xargs -r tdnf remove -y || true; \
	tdnf clean all; \
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc /tmp/rpm-before.txt /tmp/rpm-after.txt; \
	php --version

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

RUN set -eux; \
	if php -m | grep -qi sodium; then \
		: ; \
	elif [ -f "$(php-config --extension-dir)/sodium.so" ]; then \
		docker-php-ext-enable sodium; \
	fi

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]
