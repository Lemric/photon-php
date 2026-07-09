# PHP 8.5 — main RPM spec for VMware Photon OS 5.x
# Produces: php85, php85-common, php85-cli, php85-fpm, php85-devel,
#           php85-opcache, php85-process, php85-mbstring, php85-intl,
#           php85-xml, php85-curl, php85-gd, php85-zip, php85-bcmath,
#           php85-soap, php85-sockets, php85-pcntl, php85-mysqlnd, php85-pgsql

%global php85_ver          8.5.8
%global php85_major        85
%global php85_api          20250812
%global php85_zend_api     420250812
%global php85_confdir      /etc/php85
%global php85_extdir       %{php85_confdir}/conf.d
%global php85_moddir       /usr/lib64/php85/modules
%global php85_includedir   /usr/include/php85
%global php85_fpm_user     php-fpm
%global php85_fpm_group    php-fpm
%global php85_fpm_logdir   /var/log/php85-fpm
%global php85_fpm_rundir   /run/php85-fpm
%global php85_cflags       -O2 -flto=auto -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC
%global php85_cxxflags     -O2 -flto=auto -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC
%global php85_ldflags      -Wl,-z,relro -Wl,-z,now -flto=auto

Name:           php85
Version:        %{php85_ver}
Release:        1%{?dist}
Summary:        PHP scripting language (version 8.5)
License:        PHP-3.01
URL:            https://www.php.net/
Source0:        https://www.php.net/distributions/php-%{version}.tar.xz
Source1:        php.ini-production
Source2:        php-fpm.conf
Source3:        www.conf
Source4:        php85-php-fpm.service
Source5:        10-opcache.ini

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  bison
BuildRequires:  re2c >= 3
BuildRequires:  openssl-devel
BuildRequires:  libxml2-devel
BuildRequires:  sqlite-devel
BuildRequires:  zlib-devel
BuildRequires:  libzip-devel
BuildRequires:  oniguruma-devel
BuildRequires:  libicu-devel
BuildRequires:  libcurl-devel
BuildRequires:  libpng-devel
BuildRequires:  libjpeg-turbo-devel
BuildRequires:  freetype-devel
BuildRequires:  libwebp-devel
BuildRequires:  postgresql-devel
BuildRequires:  systemd-devel

Provides:       php = %{version}
Provides:       php-cli = %{version}
Provides:       php-fpm = %{version}
Provides:       php-common = %{version}

%include php85-common.spec
%include php85-cli.spec
%include php85-fpm.spec
%include php85-devel.spec

%package opcache
Summary:        OPcache extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description opcache
The Zend OPcache extension provides fast bytecode caching for PHP.

%files opcache
%defattr(-,root,root,-)
%{php85_moddir}/opcache.so
%config(noreplace) %{php85_extdir}/10-opcache.ini

%package process
Summary:        process extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description process
The process extension provides process control functions.

%files process
%defattr(-,root,root,-)
%{php85_moddir}/sysvmsg.so
%{php85_moddir}/sysvsem.so
%{php85_moddir}/sysvshm.so

%package mbstring
Summary:        mbstring extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       oniguruma

%description mbstring
Multibyte string handling extension for PHP.

%files mbstring
%defattr(-,root,root,-)
%{php85_moddir}/mbstring.so
%config(noreplace) %{php85_extdir}/20-mbstring.ini

%package intl
Summary:        intl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libicu

%description intl
Internationalization extension for PHP.

%files intl
%defattr(-,root,root,-)
%{php85_moddir}/intl.so
%config(noreplace) %{php85_extdir}/20-intl.ini

%package xml
Summary:        XML extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libxml2

%description xml
DOM, SimpleXML, XML, XMLReader and XMLWriter extensions for PHP.

%files xml
%defattr(-,root,root,-)
%{php85_moddir}/dom.so
%{php85_moddir}/simplexml.so
%{php85_moddir}/xml.so
%{php85_moddir}/xmlreader.so
%{php85_moddir}/xmlwriter.so
%config(noreplace) %{php85_extdir}/20-xml.ini

%package curl
Summary:        curl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libcurl

%description curl
cURL extension for PHP.

%files curl
%defattr(-,root,root,-)
%{php85_moddir}/curl.so
%config(noreplace) %{php85_extdir}/20-curl.ini

%package gd
Summary:        GD imaging extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libpng
Requires:       libjpeg-turbo
Requires:       freetype
Requires:       libwebp

%description gd
GD imaging library extension for PHP.

%files gd
%defattr(-,root,root,-)
%{php85_moddir}/gd.so
%config(noreplace) %{php85_extdir}/20-gd.ini

%package zip
Summary:        zip extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libzip

%description zip
ZIP archive handling extension for PHP.

%files zip
%defattr(-,root,root,-)
%{php85_moddir}/zip.so
%config(noreplace) %{php85_extdir}/20-zip.ini

%package bcmath
Summary:        bcmath extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description bcmath
Arbitrary precision mathematics extension for PHP.

%files bcmath
%defattr(-,root,root,-)
%{php85_moddir}/bcmath.so
%config(noreplace) %{php85_extdir}/20-bcmath.ini

%package soap
Summary:        SOAP extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       %{name}-xml = %{version}-%{release}

%description soap
SOAP protocol extension for PHP.

%files soap
%defattr(-,root,root,-)
%{php85_moddir}/soap.so
%config(noreplace) %{php85_extdir}/20-soap.ini

%package sockets
Summary:        sockets extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description sockets
Low-level socket interface extension for PHP.

%files sockets
%defattr(-,root,root,-)
%{php85_moddir}/sockets.so
%config(noreplace) %{php85_extdir}/20-sockets.ini

%package pcntl
Summary:        pcntl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description pcntl
Process Control extension for PHP (CLI only).

%files pcntl
%defattr(-,root,root,-)
%{php85_moddir}/pcntl.so
%config(noreplace) %{php85_extdir}/20-pcntl.ini

%package mysqlnd
Summary:        MySQL Native Driver extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description mysqlnd
MySQL Native Driver with mysqli and PDO MySQL extensions.

%files mysqlnd
%defattr(-,root,root,-)
%{php85_moddir}/mysqli.so
%{php85_moddir}/pdo_mysql.so
%config(noreplace) %{php85_extdir}/20-mysqlnd.ini

%package pgsql
Summary:        PostgreSQL extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       postgresql-libs

%description pgsql
PostgreSQL database extensions (pgsql and pdo_pgsql) for PHP.

%files pgsql
%defattr(-,root,root,-)
%{php85_moddir}/pgsql.so
%{php85_moddir}/pdo_pgsql.so
%config(noreplace) %{php85_extdir}/20-pgsql.ini

%description
PHP is an HTML-embedded scripting language. This meta-package pulls in
the PHP %{version} CLI interpreter and common files.

%prep
%autosetup -n php-%{version}

%build
export CFLAGS="%{php85_cflags}"
export CXXFLAGS="%{php85_cxxflags}"
export LDFLAGS="%{php85_ldflags}"

./buildconf --force

./configure \
    --prefix=/usr \
    --exec-prefix=/usr \
    --sysconfdir=%{php85_confdir} \
    --with-config-file-path=%{php85_confdir} \
    --with-config-file-scan-dir=%{php85_extdir} \
    --libdir=%{_libdir} \
    --includedir=%{php85_includedir} \
    --localstatedir=/var \
    --enable-fpm \
    --with-fpm-user=%{php85_fpm_user} \
    --with-fpm-group=%{php85_fpm_group} \
    --with-fpm-acl \
    --enable-cli \
    --enable-opcache=shared \
    --enable-mbstring=shared \
    --enable-intl=shared \
    --enable-bcmath=shared \
    --enable-soap=shared \
    --enable-sockets=shared \
    --enable-pcntl=shared \
    --enable-sysvmsg=shared \
    --enable-sysvsem=shared \
    --enable-sysvshm=shared \
    --with-openssl \
    --with-zlib \
    --with-curl \
    --with-libxml \
    --with-zip \
    --with-pdo-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pgsql \
    --with-pdo-pgsql \
    --enable-gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --enable-shared \
    --disable-static \
    --disable-debug \
    --disable-rpath \
    --without-pear \
    --enable-embed=shared

%make_build

%install
%make_install

install -d %{buildroot}%{php85_confdir}
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
install -d %{buildroot}%{php85_fpm_logdir}
install -d %{buildroot}%{php85_fpm_rundir}
install -d %{buildroot}/var/lib/php85-fpm
install -d %{buildroot}%{_unitdir}

install -m 0644 %{SOURCE1} %{buildroot}%{php85_confdir}/php.ini
install -m 0644 %{SOURCE2} %{buildroot}%{php85_confdir}/php-fpm.conf
install -d %{buildroot}%{php85_confdir}/php-fpm.d
install -m 0644 %{SOURCE3} %{buildroot}%{php85_confdir}/php-fpm.d/www.conf
install -m 0644 %{SOURCE4} %{buildroot}%{_unitdir}/php85-php-fpm.service
install -m 0644 %{SOURCE5} %{buildroot}%{php85_extdir}/10-opcache.ini

for ext in mbstring intl curl gd zip bcmath soap sockets pcntl; do
    echo "extension=${ext}.so" > %{buildroot}%{php85_extdir}/20-${ext}.ini
done

cat > %{buildroot}%{php85_extdir}/20-xml.ini << 'XMLEOF'
extension=dom.so
extension=simplexml.so
extension=xml.so
extension=xmlreader.so
extension=xmlwriter.so
XMLEOF

cat > %{buildroot}%{php85_extdir}/20-mysqlnd.ini << 'MYSQLEOF'
extension=mysqli.so
extension=pdo_mysql.so
MYSQLEOF

cat > %{buildroot}%{php85_extdir}/20-pgsql.ini << 'PGSQLEOF'
extension=pgsql.so
extension=pdo_pgsql.so
PGSQLEOF

mv %{buildroot}%{_libdir}/php/modules/*.so %{buildroot}%{php85_moddir}/ 2>/dev/null || true
find %{buildroot}%{_libdir} -path '*/php/modules/*.so' -exec mv {} %{buildroot}%{php85_moddir}/ \; 2>/dev/null || true

if [ -f %{buildroot}%{_libdir}/libphp.so ]; then
    mv %{buildroot}%{_libdir}/libphp.so %{buildroot}%{_libdir}/libphp85.so
fi

find %{buildroot}%{php85_moddir} -name '*.so' -exec strip --strip-unneeded {} \;

rm -rf %{buildroot}%{_libdir}/php
rm -rf %{buildroot}%{_libdir}/php85
rm -rf %{buildroot}%{_datadir}/php
rm -rf %{buildroot}%{_localstatedir}/log/php-fpm.log 2>/dev/null || true

%check
%{buildroot}%{_bindir}/php -v
%{buildroot}%{_bindir}/php -m | head -20

Requires:       %{name}-cli = %{version}-%{release}
Requires:       %{name}-common = %{version}-%{release}

%files
%defattr(-,root,root,-)
%license LICENSE
%doc README.md

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.8-1
- Initial PHP 8.5.8 build for VMware Photon OS 5.x
