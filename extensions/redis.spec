%include macros.inc

%define php85_extname redis

Name:           php85-pecl-redis
Version:        6.2.0
Release:        1%{?dist}
Summary:        PHP %{php85_ver} Redis extension (PECL)
License:        PHP-3.01
URL:            https://pecl.php.net/package/redis
Source0:        https://pecl.php.net/get/redis-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}
Recommends:     php85-pecl-igbinary

%description
The phpredis extension provides an API for communicating with Redis
key-value stores. Built with igbinary serializer support.

%prep
%autosetup -n redis-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
%{__phpize}
./configure --enable-redis-igbinary --enable-redis-lzf --enable-redis-zstd
%make_build

%install
%make_install
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ -f modules/redis.so ]; then
    install -m 0755 modules/redis.so %{buildroot}%{php85_moddir}/redis.so
fi
echo "extension=redis.so" > %{buildroot}%{php85_extdir}/30-redis.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/redis.so
%config(noreplace) %{php85_extdir}/30-redis.ini

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 6.2.0-1
- Initial redis PECL build for PHP 8.5 on Photon OS
