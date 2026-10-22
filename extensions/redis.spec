%include macros.inc

%define php_extname redis

Name:           php%{php_major}-pecl-redis
Version:        6.3.0
Release:        4%{?dist}
Summary:        PHP %{php_ver} Redis extension (PECL)
License:        PHP-3.01
URL:            https://github.com/phpredis/phpredis
Source0:        https://github.com/phpredis/phpredis/archive/%{version}/redis-%{version}.tar.gz

BuildRequires:  php%{php_major}-devel = %{php_ver}
BuildRequires:  php%{php_major}-pecl-igbinary
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config

Requires:       php%{php_major}-common = %{php_ver}
Requires:       php%{php_major}-cli = %{php_ver}
Recommends:     php%{php_major}-pecl-igbinary

%description
The phpredis extension provides an API for communicating with Redis
key-value stores. Built with igbinary serializer support.

%prep
%autosetup -n phpredis-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
%{__phpize}
./configure --enable-redis-igbinary
%make_build

%install
%make_install
install -d %{buildroot}%{php_extdir}
install -d %{buildroot}%{php_moddir}
if [ ! -f modules/redis.so ]; then
    echo "ERROR: redis.so was not built" >&2
    exit 1
fi
install -m 0755 modules/redis.so %{buildroot}%{php_moddir}/redis.so
echo "extension=redis.so" > %{buildroot}%{php_extdir}/30-redis.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php_moddir}/redis.so
%config(noreplace) %{php_extdir}/30-redis.ini

%changelog
* Thu Oct 22 2026 Photon PHP Build <build@photon-php.local> - 6.3.0-4
- Fetch sources from GitHub instead of pecl.php.net

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 6.3.0-3
- Rebuild against PHP 8.5.12

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 6.3.0-2
- Rebuild against PHP 8.5.11

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 6.3.0-1
- Upgrade for PHP 8.5 (php_smart_string.h removed upstream)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 6.2.0-1
- Initial redis PECL build for PHP 8.5 on Photon OS
